package com.zenelk.t9;

import android.content.Context;
import android.database.Cursor;
import android.database.sqlite.SQLiteDatabase;
import android.util.Pair;

import com.readystatesoftware.sqliteasset.SQLiteAssetHelper;

import java.util.ArrayList;
import java.util.List;

public class DatabaseInterface extends SQLiteAssetHelper {
    private static final String FORMAT_LOOKUP = "SELECT * FROM Words WHERE t9 = ?";

    private SQLiteDatabase _db;

    public DatabaseInterface(Context context, String databaseAssetName) {
        super(context, databaseAssetName, null, 1);
        _db = getWritableDatabase();
    }

    public List<Pair<String, Integer>> lookup(String s) {
        Cursor c = _db.rawQuery(FORMAT_LOOKUP, new String[] { s });
        if (!c.moveToFirst()) {
            c.close();
            return null;
        }
        List<Pair<String, Integer>> result = new ArrayList<>();
        do {
            String word = c.getString(1);
            Integer frequency = c.getInt(3);
            result.add(new Pair<>(word, frequency));
        }
        while (c.moveToNext());
        c.close();
        return result;
    }
}
