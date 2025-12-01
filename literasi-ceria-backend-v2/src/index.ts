'use strict';

// Helper function untuk memaksa izin
async function forcePermission(strapi: any, roleType: string, apiName: string, action: string, fields: string[]) {
  try {
    // 1. Temukan ID role (cth: 'authenticated' atau 'public')
    const role = await strapi
      .query('plugin::users-permissions.role')
      .findOne({ where: { type: roleType } });

    if (!role) {
      console.error(`Role "${roleType}" tidak ditemukan.`);
      return;
    }

    // 2. Tentukan nama aksi (cth: 'api::student.student.find')
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

    // 5. MEMPERBARUI IZIN (Ini akan memaksa semua field)
    await strapi.query('plugin::users-permissions.permission').update({
      where: {
        action: actionName,
        role: role.id,
      },
      data: {
        fields: fields, // <-- KUNCI UTAMA
      },
    });

    console.log(`✅ Izin "${actionName}" BERHASIL DI-UPDATE dengan fields: ${fields.join(', ')}`);

  } catch (error) {
    console.error(`❌ Gagal mem-bootstrap izin untuk ${apiName}.${action}:`, error.message);
  }
}

// Fungsi untuk mendapatkan semua field dari sebuah contentType
function getApiFields(strapi: any, apiName: string) {
  const apiId = `api::${apiName}.${apiName}`;
  const api = strapi.contentType(apiId);
  if (api) {
    // Kita filter 'createdBy' dan 'updatedBy' karena sering error
    const fields = Object.keys(api.attributes).filter(
      (key) => key !== 'createdBy' && key !== 'updatedBy'
    );
    return fields;
  }
  console.error(`ERROR: Tipe konten "${apiId}" tidak ditemukan.`);
  return null;
}

export default {
  /**
   * An asynchronous bootstrap function that runs before
   * your application gets started.
   */
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
      // === INI PERBAIKAN BARUNYA (Masalah Error 404) ===
      await forcePermission(strapi, 'public', 'content', 'findOne', contentFieldsPublic);
      // === AKHIR PERBAIKAN BARU ===
    }
    const kuisFieldsPublic = getApiFields(strapi, 'quiz');
    if (kuisFieldsPublic) {
      await forcePermission(strapi, 'public', 'quiz', 'find', kuisFieldsPublic);
      // (Kita tambahkan 'findOne' juga untuk jaga-jaga)
      await forcePermission(strapi, 'public', 'quiz', 'findOne', kuisFieldsPublic);
    }
    const studentFieldsPublic = getApiFields(strapi, 'student');
    if (studentFieldsPublic) {
      await forcePermission(strapi, 'public', 'student', 'find', studentFieldsPublic);
    }

    // --- 3. IZIN ROLE "PUBLIC" (UPLOAD/MEDIA LIBRARY) ---
    // Ini untuk 'file_konten' (Video) dan 'foto_profil' (Gambar)
    const uploadFields = ['url', 'name', 'mime', 'size', 'width', 'height', 'formats'];
    // Perhatikan: Nama API untuk Upload adalah 'upload', tapi action-nya adalah 'plugin::upload.file.find'
    // Kode helper kita tidak dirancang untuk ini. Kita akan skip 'upload' untuk sekarang.
    // Kita sudah mengaturnya di Langkah 9.2 (yang lama) dan seharusnya itu sudah cukup.
    // Jika 'foto_profil' gagal dimuat, kita akan perbaiki nanti.
  },
};