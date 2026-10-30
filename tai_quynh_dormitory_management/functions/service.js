'use strict';

const { randomUUID } = require('node:crypto');

const {
  RULES_VERSION,
  MAX_PHOTO_BYTES,
  DEFAULT_FINE,
  VIOLATION_RULES,
  requireThat,
  vietnamDay,
  attendanceWindow,
  weekStart,
  assertAdmin,
  assertManager,
  imageMime,
} = require('./discipline');

async function savePrivateEvidence(
  bucket,
  prefix,
  bytes,
  mime,
) {
  // Tên ảnh do máy chủ tạo, mỗi lần lưu có tên riêng.
  const path = `${prefix}/${randomUUID()}`;

  // Admin GCS upload không tạo Firebase download token công khai.
  await bucket.file(path).save(bytes, {
    resumable: false,
    preconditionOpts: {
      ifGenerationMatch: 0,
    },
    metadata: {
      contentType: mime,
    },
  });

  return path;
}

function createService({
  db,
  bucket,
  timestamp,
  now = () => new Date(),
}) {
  const col = name => db.collection(`v2_${name}`);

  const rowRef = (day, uid) =>
    col('attendance').doc(`${day}_${uid}`);

  async function actor(auth) {
    requireThat(
      auth,
      'Vui lòng đăng nhập.',
      'unauthenticated',
    );

    const found = await col('users')
      .where('owner_uid', '==', auth.uid)
      .limit(2)
      .get();

    requireThat(
      found.docs.length === 1,
      'Hồ sơ không hợp lệ.',
      'permission-denied',
    );

    const profile = found.docs[0].data();

    requireThat(
      profile.role !== 'admin' ||
        auth.token.admin === true,
      'Quyền admin không hợp lệ.',
      'permission-denied',
    );

    return {
      ...profile,
      uid: auth.uid,
    };
  }

  async function reviewManager(
    admin,
    { username, buildingId, approve },
  ) {
    assertAdmin(admin);

    requireThat(
      typeof approve === 'boolean',
      'Quyết định duyệt không hợp lệ.',
    );

    requireThat(
      typeof username === 'string' &&
        /^[a-z0-9_]{3,40}$/.test(username),
      'Tài khoản không hợp lệ.',
    );

    const ref = col('users').doc(username);

    let roomRef;

    if (approve === true) {
      requireThat(
        typeof buildingId === 'string' &&
          buildingId.trim(),
        'Hãy chọn tòa quản lý.',
      );

      const rooms = await col('rooms')
        .where('building_id', '==', buildingId)
        .limit(1)
        .get();

      requireThat(
        rooms.docs.length,
        'Tòa chưa có phòng hợp lệ.',
      );

      roomRef = rooms.docs[0].ref;
    }

    await db.runTransaction(async tx => {
      const user = (await tx.get(ref)).data();

      requireThat(
        user?.role === 'buildingManager',
        'Không tìm thấy tài khoản quản lý tòa.',
      );

      requireThat(
        user.rules_version === RULES_VERSION &&
          user.rules_accepted_at,
        'Tài khoản chưa đồng ý nội quy hiện hành.',
      );

      const target = approve === true
        ? buildingId
        : user.managed_building_id;

      const assignment = target
        ? col('manager_assignments').doc(
            encodeURIComponent(target),
          )
        : null;

      const slots = assignment
        ? ((await tx.get(assignment)).data()?.usernames || [])
        : [];

      if (approve === true) {
        requireThat(
          (await tx.get(roomRef)).exists,
          'Tòa không còn phòng.',
        );

        requireThat(
          user.manager_status !== 'approved',
          'Tài khoản đã được duyệt.',
        );

        requireThat(
          slots.includes(username) || slots.length < 2,
          'Tòa đã đủ 2 người quản lý.',
        );

        tx.set(assignment, {
          building_id: target,
          usernames: [...new Set([...slots, username])],
        });
      } else if (assignment) {
        tx.set(assignment, {
          building_id: target,
          usernames: slots.filter(name => name !== username),
        });
      }

      tx.update(ref, {
        manager_status: approve === true
          ? 'approved'
          : 'rejected',
        managed_building_id: approve === true
          ? buildingId
          : null,
        reviewed_by: admin.username,
        reviewed_at: timestamp(),
      });
    });

    return { success: true };
  }

  async function managedResidents(manager) {
    assertManager(
      manager,
      manager.managed_building_id,
    );

    requireThat(
      manager.role === 'buildingManager',
      'Dành cho quản lý tòa.',
    );

    const rooms = await col('rooms')
      .where(
        'building_id',
        '==',
        manager.managed_building_id,
      )
      .get();

    const result = [];

    for (const room of rooms.docs) {
      const residents = await col('users')
        .where('pending_room_doc', '==', room.id)
        .where('role', '==', 'student')
        .where('room_status', '==', 'approved')
        .get();

      for (const student of residents.docs) {
        const user = student.data();

        result.push({
          username: student.id,
          full_name: user.full_name || student.id,
          mssv: user.mssv || '',
          room_name: room.data().label,
          building_id: manager.managed_building_id,
        });
      }
    }

    return { residents: result };
  }

  async function openAttendance(day = vietnamDay(now())) {
    const time = now();
    const { open, close } = attendanceWindow(day);

    requireThat(
      time >= open && time < close,
      'Chưa đến giờ mở điểm danh hoặc đã quá hạn.',
    );

    const session = col('attendance_sessions').doc(day);

    const reservation = await db.runTransaction(async tx => {
      const existing = (await tx.get(session)).data();

      if (
        existing?.status === 'open' ||
        existing?.status === 'closed'
      ) {
        return false;
      }

      if (!existing) {
        tx.set(session, {
          status: 'opening',
          opened_at: open.toISOString(),
          day,
        });
      }

      return true;
    });

    if (!reservation) return;

    const cutoff = new Date(
      (await session.get()).data().opened_at,
    );

    const users = await col('users')
      .where('role', '==', 'student')
      .where('room_status', '==', 'approved')
      .get();

    for (const doc of users.docs) {
      const user = doc.data();

      if (!user.owner_uid || !user.pending_room_doc) {
        continue;
      }

      const approvedAt = user.room_approved_at?.toDate?.();

      if (approvedAt && approvedAt > cutoff) {
        continue;
      }

      const room = (
        await col('rooms').doc(user.pending_room_doc).get()
      ).data();

      if (!room?.building_id) continue;

      const ref = rowRef(day, user.owner_uid);

      await db.runTransaction(async tx => {
        if ((await tx.get(ref)).exists) return;

        tx.set(ref, {
          day,
          week_start: weekStart(day),
          owner_uid: user.owner_uid,
          username: doc.id,
          student_name: user.full_name || doc.id,
          mssv: user.mssv || '',
          room_doc: user.pending_room_doc,
          room_name: room.label,
          building_id: room.building_id,
          status: 'awaiting',
          created_at: timestamp(),
        });
      });
    }

    await db.runTransaction(async tx => {
      const current = (await tx.get(session)).data();

      if (current?.status === 'opening') {
        tx.update(session, {
          status: now() < close ? 'open' : 'failed',
        });
      }
    });
  }

  async function submitAttendance(
    student,
    { photoBase64, requestId },
  ) {
    requireThat(
      student.role === 'student',
      'Chỉ sinh viên được điểm danh.',
      'permission-denied',
    );

    const day = vietnamDay(now());
    const { open, close } = attendanceWindow(day);

    requireThat(
      now() >= open && now() < close,
      'Chỉ nhận điểm danh từ 22:00 đến trước 22:10 (giờ Việt Nam).',
    );

    requireThat(
      typeof requestId === 'string' &&
        /^[a-zA-Z0-9_-]{10,80}$/.test(requestId),
      'Mã ảnh không hợp lệ.',
    );

    requireThat(
      typeof photoBase64 === 'string' &&
        photoBase64.length > 0 &&
        photoBase64.length <= 4 * Math.ceil(MAX_PHOTO_BYTES / 3),
      'Ảnh tối đa 2 MB.',
    );

    const bytes = Buffer.from(photoBase64, 'base64');

    requireThat(
      bytes.length <= MAX_PHOTO_BYTES &&
        bytes.toString('base64') === photoBase64,
      'Dữ liệu ảnh không hợp lệ.',
    );

    const mime = imageMime(bytes);
    const ref = rowRef(day, student.uid);
    const before = (await ref.get()).data();

    requireThat(
      before,
      'Bạn không có trong danh sách cư trú đầu phiên. '
        + 'Liên hệ quản lý tòa.',
    );

    if (before.request_id === requestId) {
      return { success: true };
    }

    requireThat(
      before.status === 'awaiting',
      'Bạn đã gửi điểm danh hôm nay.',
    );

    const path = await savePrivateEvidence(
      bucket,
      `attendance/${day}/${student.uid}`,
      bytes,
      mime,
    );

    try {
      await db.runTransaction(async tx => {
        const row = (await tx.get(ref)).data();

        const session = (
          await tx.get(col('attendance_sessions').doc(day))
        ).data();

        requireThat(
          session?.status === 'open',
          'Phiên chưa mở xong. '
            + 'Vui lòng chờ và gửi lại trước 22:10.',
        );

        requireThat(
          row,
          'Bạn không có trong danh sách cư trú đầu phiên.',
        );

        if (row.request_id === requestId) return;

        requireThat(
          row.status === 'awaiting',
          'Bạn đã gửi điểm danh hôm nay.',
        );

        requireThat(
          now() < close,
          'Đã hết thời gian điểm danh.',
        );

        tx.update(ref, {
          evidence_path: path,
          evidence_type: mime,
          request_id: requestId,
          status: 'submitted',
          submitted_at: timestamp(),
        });
      });
    } catch (error) {
      // Không xóa ảnh nếu giao dịch có thể đã ghi thành công
      // nhưng phản hồi bị mất do lỗi mạng.
      const persisted = await ref.get().catch(() => null);

      if (
        persisted &&
        persisted.data()?.evidence_path !== path
      ) {
        await bucket
          .file(path)
          .delete({ ignoreNotFound: true })
          .catch(() => {});
      }

      throw error;
    }

    // Dọn ảnh thừa của yêu cầu gửi lại đồng thời.
    if ((await ref.get()).data()?.evidence_path !== path) {
      await bucket.file(path).delete({
        ignoreNotFound: true,
      });
    }

    return { success: true };
  }

  async function violation(
    tx,
    ref,
    row,
    reason,
    reviewer,
  ) {
    const record = col('violations').doc(ref.id);
    const existing = await tx.get(record);

    if (!existing.exists) {
      tx.set(record, {
        day: row.day,
        week_start: row.week_start,
        owner_uid: row.owner_uid,
        username: row.username,
        student_name: row.student_name,
        mssv: row.mssv,
        room_name: row.room_name,
        building_id: row.building_id,
        reason,
        rule_id: 'attendance',
        fine_amount: DEFAULT_FINE,
        currency: 'VND',
        created_at: timestamp(),
        reviewed_by: reviewer,
      });
    }

    tx.update(ref, {
      status: 'violation',
      reason,
      reviewed_by: reviewer,
      reviewed_at: timestamp(),
    });
  }

  async function closeAttendance(day = vietnamDay(now())) {
    const { close } = attendanceWindow(day);

    requireThat(
      now() >= close,
      'Chưa hết giờ điểm danh.',
    );

    const session = col('attendance_sessions').doc(day);
    const data = (await session.get()).data();

    // Phiên chưa mở thành công thì không tự phạt bù.
    if (data?.status !== 'open') return;

    const rows = await col('attendance')
      .where('day', '==', day)
      .where('status', '==', 'awaiting')
      .get();

    for (const doc of rows.docs) {
      await db.runTransaction(async tx => {
        const row = (await tx.get(doc.ref)).data();

        if (row?.status === 'awaiting') {
          await violation(
            tx,
            doc.ref,
            row,
            'Không nộp ảnh trước 22:10',
            'system',
          );
        }
      });
    }

    await session.update({
      status: 'closed',
      closed_at: timestamp(),
    });
  }

  async function reviewEvidence(
    manager,
    { attendanceId, accept, reason },
  ) {
    requireThat(
      typeof attendanceId === 'string' &&
        !attendanceId.includes('/'),
      'Lượt điểm danh không hợp lệ.',
    );

    requireThat(
      typeof accept === 'boolean',
      'Quyết định không hợp lệ.',
    );

    if (!accept) {
      requireThat(
        typeof reason === 'string' &&
          reason.trim().length >= 5 &&
          reason.length <= 500,
        'Hãy nhập lý do ảnh không hợp lệ (5–500 ký tự).',
      );
    }

    const ref = col('attendance').doc(attendanceId);

    await db.runTransaction(async tx => {
      const row = (await tx.get(ref)).data();

      requireThat(row, 'Không tìm thấy điểm danh.');

      assertManager(manager, row.building_id);

      requireThat(
        row.status === 'submitted',
        'Minh chứng đã được xử lý hoặc chưa được nộp.',
      );

      if (accept) {
        tx.update(ref, {
          status: 'accepted',
          reviewed_by: manager.username,
          reviewed_at: timestamp(),
        });
      } else {
        await violation(
          tx,
          ref,
          row,
          reason.trim(),
          manager.username,
        );
      }
    });

    return { success: true };
  }

  async function evidencePhoto(
    viewer,
    { attendanceId },
  ) {
    requireThat(
      typeof attendanceId === 'string' &&
        !attendanceId.includes('/'),
      'Lượt điểm danh không hợp lệ.',
    );

    const row = (
      await col('attendance').doc(attendanceId).get()
    ).data();

    requireThat(
      row?.evidence_path,
      'Chưa có minh chứng.',
    );

    const ownEvidence =
      viewer.role === 'student' &&
      viewer.uid === row.owner_uid;

    if (!ownEvidence) {
      assertManager(viewer, row.building_id);
    }

    const file = bucket.file(row.evidence_path);
    const [metadata] = await file.getMetadata();

    requireThat(
      Number(metadata.size) <= MAX_PHOTO_BYTES,
      'Ảnh vượt quá dung lượng cho phép.',
    );

    const [bytes] = await file.download();

    return {
      base64: bytes.toString('base64'),
    };
  }

  async function recordViolation(
    manager,
    { username, ruleId, note, requestId },
  ) {
    requireThat(
      typeof username === 'string' &&
        /^[a-z0-9_]{3,40}$/.test(username),
      'Tài khoản không hợp lệ.',
    );

    requireThat(
      Object.hasOwn(VIOLATION_RULES, ruleId) &&
        ruleId !== 'attendance',
      'Hãy chọn hành vi vi phạm.',
    );

    requireThat(
      typeof note === 'string' &&
        note.trim().length >= 5 &&
        note.length <= 500,
      'Hãy mô tả sự việc (5–500 ký tự).',
    );

    requireThat(
      typeof requestId === 'string' &&
        /^[a-zA-Z0-9_-]{10,80}$/.test(requestId),
      'Mã ghi nhận không hợp lệ.',
    );

    const ref = col('violations').doc(
      `manual_${manager.uid}_${requestId}`,
    );

    await db.runTransaction(async tx => {
      const user = (
        await tx.get(col('users').doc(username))
      ).data();

      requireThat(
        user?.role === 'student' &&
          user.room_status === 'approved' &&
          user.pending_room_doc,
        'Sinh viên chưa được duyệt cư trú.',
      );

      const room = (
        await tx.get(
          col('rooms').doc(user.pending_room_doc),
        )
      ).data();

      requireThat(
        room,
        'Không tìm thấy phòng cư trú.',
      );

      assertManager(manager, room.building_id);

      const existing = await tx.get(ref);

      if (existing.exists) {
        requireThat(
          existing.data().username === username &&
            existing.data().rule_id === ruleId &&
            existing.data().reason ===
              `${VIOLATION_RULES[ruleId]}: ${note.trim()}`,
          'Mã sự việc đã được sử dụng cho một vi phạm khác.',
        );

        return;
      }

      const day = vietnamDay(now());

      tx.set(ref, {
        day,
        week_start: weekStart(day),
        owner_uid: user.owner_uid,
        username,
        student_name: user.full_name || username,
        mssv: user.mssv || '',
        room_name: room.label,
        building_id: room.building_id,
        rule_id: ruleId,
        reason: `${VIOLATION_RULES[ruleId]}: ${note.trim()}`,
        fine_amount: DEFAULT_FINE,
        currency: 'VND',
        created_at: timestamp(),
        reviewed_by: manager.username,
      });
    });

    return { success: true };
  }

  return {
    actor,
    reviewManager,
    managedResidents,
    openAttendance,
    submitAttendance,
    closeAttendance,
    reviewEvidence,
    evidencePhoto,
    recordViolation,
  };
}

module.exports = {
  createService,
  savePrivateEvidence,
};