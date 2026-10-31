'use strict';

const RULES_VERSION = '2026-10-30';
const MAX_PHOTO_BYTES = 2 * 1024 * 1024;
const DEFAULT_FINE = 50000;

const VIOLATION_RULES = {
  attendance: 'Không điểm danh đúng hạn / minh chứng không hợp lệ',
  noise: 'Gây ồn, làm mất trật tự sau 22:00',
  hygiene: 'Xả rác, không giữ vệ sinh phòng và khu vực chung',
  property: 'Làm hư hỏng, tự ý tháo dỡ thiết bị ký túc xá',
  room_transfer: 'Tự ý chuyển phòng hoặc cho người khác ở thay',
  visitor: 'Đưa khách ở lại qua đêm khi chưa được phép',
};

const VN_OFFSET = 7 * 60 * 60 * 1000;

class DomainError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

function requireThat(
  condition,
  message,
  code = 'failed-precondition',
) {
  if (!condition) {
    throw new DomainError(code, message);
  }
}

function vietnamDay(now) {
  return new Date(now.getTime() + VN_OFFSET)
    .toISOString()
    .slice(0, 10);
}

function attendanceWindow(day) {
  requireThat(
    /^\d{4}-\d{2}-\d{2}$/.test(day),
    'Ngày không hợp lệ.',
  );

  const open = new Date(`${day}T22:00:00+07:00`);

  requireThat(
    !Number.isNaN(open.getTime()) &&
      vietnamDay(open) === day,
    'Ngày không hợp lệ.',
  );

  return {
    open,
    close: new Date(open.getTime() + 10 * 60 * 1000),
  };
}

function weekStart(day) {
  attendanceWindow(day);

  const date = new Date(`${day}T00:00:00Z`);

  date.setUTCDate(
    date.getUTCDate() - (date.getUTCDay() + 6) % 7,
  );

  return date.toISOString().slice(0, 10);
}

function canManage(actor, building) {
  return actor.role === 'admin' ||
    (
      actor.role === 'buildingManager' &&
      actor.manager_status === 'approved' &&
      actor.managed_building_id === building
    );
}

function assertManager(actor, building) {
  requireThat(
    canManage(actor, building),
    'Bạn không có quyền quản lý tòa này.',
    'permission-denied',
  );
}

function assertAdmin(actor) {
  requireThat(
    actor.role === 'admin',
    'Chỉ admin được thực hiện thao tác này.',
    'permission-denied',
  );
}

function imageMime(bytes) {
  if (
    bytes.length >= 3 &&
    bytes[0] === 0xff &&
    bytes[1] === 0xd8 &&
    bytes[2] === 0xff
  ) {
    return 'image/jpeg';
  }

  if (
    bytes.length >= 8 &&
    bytes.subarray(0, 8).equals(
      Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
    )
  ) {
    return 'image/png';
  }

  if (
    bytes.length >= 12 &&
    bytes.toString('ascii', 0, 4) === 'RIFF' &&
    bytes.toString('ascii', 8, 12) === 'WEBP'
  ) {
    return 'image/webp';
  }

  throw new DomainError(
    'invalid-argument',
    'Chỉ chấp nhận ảnh JPEG, PNG hoặc WebP.',
  );
}

module.exports = {
  RULES_VERSION,
  MAX_PHOTO_BYTES,
  DEFAULT_FINE,
  VIOLATION_RULES,
  DomainError,
  requireThat,
  vietnamDay,
  attendanceWindow,
  weekStart,
  canManage,
  assertManager,
  assertAdmin,
  imageMime,
};