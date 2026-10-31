'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { createService } = require('../service');
const { RULES_VERSION, DomainError } = require('../discipline');

// Small Firestore fake for the two Cloud Functions used by room cards
// and the building-manager approval workflow. No Firebase project required.
function fakeFirestore(seed) {
  const state = new Map(
    Object.entries(seed).map(([collection, docs]) => [
      collection,
      new Map(Object.entries(docs)),
    ]),
  );

  function docsOf(collection) {
    if (!state.has(collection)) state.set(collection, new Map());
    return state.get(collection);
  }

  function reference(collection, id) {
    return {
      id,
      collection,
      async get() {
        const data = docsOf(collection).get(id);
        return {
          id,
          ref: this,
          exists: data !== undefined,
          data: () => data,
        };
      },
    };
  }

  function query(collection, filters = [], maximum = Infinity) {
    return {
      where(field, op, value) {
        assert.equal(op, '==');
        return query(collection, [...filters, [field, value]], maximum);
      },
      limit(n) {
        return query(collection, filters, n);
      },
      async get() {
        const docs = [...docsOf(collection).entries()]
          .filter(([, data]) =>
            filters.every(([field, value]) => data[field] === value))
          .slice(0, maximum)
          .map(([id, data]) => ({
            id,
            ref: reference(collection, id),
            exists: true,
            data: () => data,
          }));
        return { docs };
      },
    };
  }

  return {
    state,
    collection(name) {
      return {
        ...query(name),
        doc(id) {
          return reference(name, id);
        },
      };
    },
    async runTransaction(callback) {
      const writes = [];
      const tx = {
        get: ref => ref.get(),
        set: (ref, data) => writes.push(['set', ref, data]),
        update: (ref, data) => writes.push(['update', ref, data]),
      };
      const value = await callback(tx);
      for (const [operation, ref, data] of writes) {
        const old = docsOf(ref.collection).get(ref.id);
        docsOf(ref.collection).set(
          ref.id,
          operation === 'update' ? { ...old, ...data } : data,
        );
      }
      return value;
    },
  };
}

function service(db) {
  return createService({
    db,
    bucket: {},
    timestamp: () => 'timestamp',
  });
}

function manager(username) {
  return {
    username,
    role: 'buildingManager',
    manager_status: 'pending',
    managed_building_id: null,
    rules_version: RULES_VERSION,
    rules_accepted_at: 'timestamp',
  };
}

test('manager approval creates a missing assignment document and limits to 2', async () => {
  const db = fakeFirestore({
    v2_users: {
      mgr1: manager('mgr1'),
      mgr2: manager('mgr2'),
      mgr3: manager('mgr3'),
    },
    v2_rooms: {
      A_a102: {
        label: 'Phòng a102 - A',
        building_id: 'A',
      },
    },
    // v2_manager_assignments intentionally absent.
  });
  const api = service(db);
  const admin = { role: 'admin', username: 'admin' };

  await api.reviewManager(admin, {
    username: 'mgr1', buildingId: 'A', approve: true,
  });
  assert.deepEqual(
    db.state.get('v2_manager_assignments').get('A').usernames,
    ['mgr1'],
  );
  assert.equal(db.state.get('v2_users').get('mgr1').manager_status, 'approved');

  await api.reviewManager(admin, {
    username: 'mgr2', buildingId: 'A', approve: true,
  });

  await assert.rejects(
    api.reviewManager(admin, {
      username: 'mgr3', buildingId: 'A', approve: true,
    }),
    error => error instanceof DomainError &&
      error.message.includes('đủ 2'),
  );

  await api.reviewManager(admin, {
    username: 'mgr1', approve: false,
  });
  await api.reviewManager(admin, {
    username: 'mgr3', buildingId: 'A', approve: true,
  });
  assert.deepEqual(
    db.state.get('v2_manager_assignments').get('A').usernames,
    ['mgr2', 'mgr3'],
  );
});

test('room residents include legacy assignments but never return private fields', async () => {
  const db = fakeFirestore({
    v2_rooms: {
      A_a102: { label: 'Phòng a102 - A', building_id: 'A' },
    },
    v2_users: {
      sv1: {
        role: 'student', room_status: 'approved',
        pending_room_doc: 'A_a102',
        pending_room_name: 'Phòng a102 - A',
        full_name: 'Bình', mssv: 'S001', phone: 'PRIVATE',
      },
      sv2: {
        role: 'student', room_status: 'approved',
        pending_room_name: 'Phòng a102 - A',
        full_name: 'An', mssv: 'S002', cccd: 'PRIVATE',
      },
      sv3: {
        role: 'student', room_status: 'pending',
        pending_room_doc: 'A_a102',
        pending_room_name: 'Phòng a102 - A',
        full_name: 'Chưa duyệt',
      },
    },
  });

  const residents = (await service(db).roomResidents(
    { role: 'student' },
    { roomId: 'A_a102' },
  )).residents;

  assert.deepEqual(residents, [
    { full_name: 'An', mssv: 'S002' },
    { full_name: 'Bình', mssv: 'S001' },
  ]);
});

test('a building manager cannot read residents in another building', async () => {
  const db = fakeFirestore({
    v2_rooms: {
      A_a102: { label: 'Phòng a102 - A', building_id: 'A' },
    },
  });

  await assert.rejects(
    service(db).roomResidents(
      {
        role: 'buildingManager',
        manager_status: 'approved',
        managed_building_id: 'B',
      },
      { roomId: 'A_a102' },
    ),
    error => error instanceof DomainError &&
      error.code === 'permission-denied',
  );
});
