package com.example.native_extend;

import android.content.Context;
import android.content.SharedPreferences;
import android.provider.Settings;
import android.util.Log;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;
import java.util.UUID;

public class DeviceUuidFactory {
    protected static final String PREFS_FILE            = "dev_id.xml";
    protected static final String DEVICE_UUID_FILE_NAME = ".dev_id.txt";
    protected static final String PREFS_DEVICE_ID       = "dev_id";
    protected static final String KEY                   = "cyril'98";
    protected static       UUID   uuid;
    private static Context appContext;

    public DeviceUuidFactory(Context context) {
        appContext = context.getApplicationContext();
        if (uuid == null) {
            synchronized (DeviceUuidFactory.class) {
                if (uuid == null) {
                    final SharedPreferences prefs = context.getSharedPreferences(PREFS_FILE, 0);
                    final String id = prefs.getString(PREFS_DEVICE_ID, null);
                    if (id != null) {
                        uuid = UUID.fromString(id);
                    } else {
                        if (recoverDeviceUuidFromSD() != null) {

                            uuid = UUID.fromString(recoverDeviceUuidFromSD());
                        } else {

                            final String androidId = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID);
                            //+ context.getPackageName()

                            try {
                                if (!"9774d56d682e549c".equals(androidId) && !"0000000000000000".equals(androidId)) {
                                    uuid = UUID.nameUUIDFromBytes(androidId.getBytes("utf8"));

                                    try {
                                        saveDeviceUuidToSD(EncryptUtils.encryptDES(uuid.toString(), KEY));
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                } else {
                                    uuid = UUID.randomUUID();
                                    try {
                                        saveDeviceUuidToSD(EncryptUtils.encryptDES(uuid.toString(), KEY));
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                    }
                                }
                            } catch (UnsupportedEncodingException e) {
                                throw new RuntimeException(e);
                            }
                        }
                        prefs.edit().putString(PREFS_DEVICE_ID, uuid.toString()).commit();
                    }
                }
            }
        }
    }

    private static File getDeviceUuidFile() {
        if (appContext != null) {
            File filesDir = appContext.getFilesDir();
            return new File(filesDir, DEVICE_UUID_FILE_NAME);
        }
        return null;
    }

    private static String recoverDeviceUuidFromSD() {
        try {
            File uuidFile = getDeviceUuidFile();
            if (uuidFile == null || !uuidFile.exists()) {
                return null;
            }
            FileReader fileReader = new FileReader(uuidFile);
            StringBuilder sb = new StringBuilder();
            char[] buffer = new char[100];
            int readCount;
            while ((readCount = fileReader.read(buffer)) > 0) {
                sb.append(buffer, 0, readCount);
            }
            fileReader.close();
            //通过UUID.fromString来检查uuid的格式正确性
            UUID uuid = UUID.fromString(EncryptUtils.decryptDES(sb.toString(), KEY));
            return uuid.toString();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    private static void saveDeviceUuidToSD(String uuid) {
        File targetFile = getDeviceUuidFile();
        if (targetFile == null) {
            return;
        }
        if (!targetFile.exists()) {
            OutputStreamWriter osw = null;
            try {
                osw = new OutputStreamWriter(new FileOutputStream(targetFile), "utf-8");
                osw.write(uuid);
                osw.flush();
            } catch (UnsupportedEncodingException e) {
                e.printStackTrace();
            } catch (FileNotFoundException e) {
                e.printStackTrace();
            } catch (IOException e) {
                e.printStackTrace();
            } finally {
                if (osw != null) {
                    try {
                        osw.close();
                    } catch (IOException e) {
                        e.printStackTrace();
                    }
                }
            }
        }
    }

    public static UUID getUuid() {
        return uuid;
    }
}
