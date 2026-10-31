'use strict';

const { initializeApp } = require('firebase-admin/app');
const {
  getFirestore,
  FieldValue,
} = require('firebase-admin/firestore');
const { getStorage } = require('firebase-admin/storage');

const {
  onCall,
  HttpsError,
} = require('firebase-functions/v2/https');

const {
  onSchedule,
} = require('firebase-functions/v2/scheduler');

const { logger } = require('firebase-functions');

const { createService } = require('./service');
const {
  DomainError,
  vietnamDay,
} = require('./discipline');

initializeApp();

const service = createService({
  db: getFirestore(),
  bucket: getStorage().bucket(),
  timestamp: () => FieldValue.serverTimestamp(),
});

const region = 'asia-southeast1';

function callable(method) {
  return onCall(
    {
      region,
      maxInstances: 10,
      memory: '512MiB',
      concurrency: 8,
    },
    async request => {
      try {
        const actor = await service.actor(request.auth);

        return await service[method](
          actor,
          request.data || {},
        );
      } catch (error) {
        if (error instanceof DomainError) {
          throw new HttpsError(
            error.code,
            error.message,
          );
        }

        logger.error('Discipline operation failed', {
          method,
          error: String(error),
        });

        throw new HttpsError(
          'internal',
          'Không thể xử lý. '
            + 'Vui lòng thử lại hoặc liên hệ admin.',
        );
      }
    },
  );
}

exports.reviewBuildingManager = callable('reviewManager');

exports.getManagedResidents = callable('managedResidents');

exports.getRoomResidents = callable('roomResidents');

exports.submitAttendance = callable('submitAttendance');

exports.reviewAttendanceEvidence = callable('reviewEvidence');

exports.getAttendanceEvidence = callable('evidencePhoto');

exports.recordDormitoryViolation = callable('recordViolation');

exports.openNightlyAttendance = onSchedule(
  {
    region,
    schedule: '0 22 * * *',
    timeZone: 'Asia/Ho_Chi_Minh',
    retryCount: 3,
    timeoutSeconds: 540,
  },
  () => service.openAttendance(),
);

exports.closeNightlyAttendance = onSchedule(
  {
    region,
    schedule: '10 22 * * *',
    timeZone: 'Asia/Ho_Chi_Minh',
    retryCount: 5,
    timeoutSeconds: 540,
  },
  () => service.closeAttendance(),
);

exports.recoverAttendance = onSchedule(
  {
    region,
    schedule: 'every 60 minutes',
    timeZone: 'Asia/Ho_Chi_Minh',
    retryCount: 3,
    timeoutSeconds: 540,
  },
  async () => {
    const sessions = await getFirestore()
      .collection('v2_attendance_sessions')
      .where('status', '==', 'open')
      .get();

    for (const doc of sessions.docs) {
      const deadline = new Date(
        `${doc.id}T22:10:00+07:00`,
      );

      if (
        doc.id < vietnamDay(new Date()) ||
        new Date() >= deadline
      ) {
        await service.closeAttendance(doc.id);
      }
    }
  },
);