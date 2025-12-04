'use strict';

// Helper function untuk memaksa izin
async function forcePermission(strapi: any, roleType: string, apiName: string, action: string, fields: string[]) {
  try {
    // 1. Temukan ID role
    const role = await strapi
      .query('plugin::users-permissions.role')
      .findOne({ where: { type: roleType } });

    if (!role) {
      console.error(`Role "${roleType}" tidak ditemukan.`);
      return;
    }

    // 2. Tentukan nama aksi
    const actionName = `api::${apiName}.${apiName}.${action}`;
    const permissionData = {
      action: actionName,
      role: role.id,
    };

    // 3. Cek apakah izin sudah ada
    const existingPermission = await strapi
      .query('plugin::users-permissions.permission')
      .findOne({ where: permissionData });

    // 4. Jika izin BELUM ADA, buat
    if (!existingPermission) {
      await strapi
        .query('plugin::users-permissions.permission')
        .create({ data: permissionData });
      console.log(`✅ Izin "${actionName}" untuk ${roleType} BERHASIL DIBUAT.`);
    } else {
      console.log(`ℹ️ Izin "${actionName}" untuk ${roleType} sudah ada.`);
    }

    // 5. MEMPERBARUI IZIN (Paksa field)
    await strapi.query('plugin::users-permissions.permission').update({
      where: {
        action: actionName,
        role: role.id,
      },
      data: {
        fields: fields,
      },
    });

    console.log(`✅ Izin "${actionName}" BERHASIL DI-UPDATE.`);

  } catch (error) {
    console.error(`❌ Gagal mem-bootstrap izin untuk ${apiName}.${action}:`, error.message);
  }
}

function getApiFields(strapi: any, apiName: string) {
  const apiId = `api::${apiName}.${apiName}`;
  const api = strapi.contentType(apiId);
  if (api) {
    const fields = Object.keys(api.attributes).filter(
      (key) => key !== 'createdBy' && key !== 'updatedBy'
    );
    return fields;
  }
  console.error(`ERROR: Tipe konten "${apiId}" tidak ditemukan.`);
  return null;
}

export default {
  async bootstrap({ strapi }: { strapi: any }) {
    console.log('🚀 Bootstrapping permissions... (Memaksa Izin...)');

    // --- 1. IZIN ROLE "AUTHENTICATED" (GURU/ORTU) ---
    const studentFields = getApiFields(strapi, 'student');
    if (studentFields) {
      await forcePermission(strapi, 'authenticated', 'student', 'find', studentFields);
    }
    const activityLogFieldsAuth = getApiFields(strapi, 'activity-log');
    if (activityLogFieldsAuth) {
      await forcePermission(strapi, 'authenticated', 'activity-log', 'find', activityLogFieldsAuth);
    }
    const contentFieldsAuth = getApiFields(strapi, 'content');
    if (contentFieldsAuth) {
      await forcePermission(strapi, 'authenticated', 'content', 'find', contentFieldsAuth);
    }

    // --- 2. IZIN ROLE "PUBLIC" (MODE ANAK) ---
    const activityLogFieldsPublic = getApiFields(strapi, 'activity-log');
    if (activityLogFieldsPublic) {
      await forcePermission(strapi, 'public', 'activity-log', 'create', activityLogFieldsPublic);
    }
    const contentFieldsPublic = getApiFields(strapi, 'content');
    if (contentFieldsPublic) {
      await forcePermission(strapi, 'public', 'content', 'find', contentFieldsPublic);
      await forcePermission(strapi, 'public', 'content', 'findOne', contentFieldsPublic);
    }
    const kuisFieldsPublic = getApiFields(strapi, 'quiz');
    if (kuisFieldsPublic) {
      await forcePermission(strapi, 'public', 'quiz', 'find', kuisFieldsPublic);
      await forcePermission(strapi, 'public', 'quiz', 'findOne', kuisFieldsPublic);
    }

    // === PERBAIKAN UTAMA: IZIN STUDENT UNTUK PUBLIC ===
    const studentFieldsPublic = getApiFields(strapi, 'student');
    if (studentFieldsPublic) {
      // Izin melihat daftar (untuk login)
      await forcePermission(strapi, 'public', 'student', 'find', studentFieldsPublic);

      // Izin melihat detail satu murid (untuk cek bintang)
      await forcePermission(strapi, 'public', 'student', 'findOne', studentFieldsPublic);

      // Izin MENGUBAH data murid (untuk tambah bintang)
      await forcePermission(strapi, 'public', 'student', 'update', studentFieldsPublic);
    }
    // ==================================================

    // --- 3. IZIN ROLE "PUBLIC" (MEDIA LIBRARY) ---
    try {
      const role = await strapi.query('plugin::users-permissions.role').findOne({ where: { type: 'public' } });
      const actionName = 'plugin::upload.read';
      const existingPermission = await strapi.query('plugin::users-permissions.permission').findOne({ where: { action: actionName, role: role.id } });
      if (!existingPermission) {
        await strapi.query('plugin::users-permissions.permission').create({ data: { action: actionName, role: role.id } });
        console.log(`✅ Izin "${actionName}" untuk public BERHASIL DIBUAT.`);
      }
    } catch (e) {
      console.error('❌ Gagal mem-bootstrap izin media:', e.message);
    }
  },
};