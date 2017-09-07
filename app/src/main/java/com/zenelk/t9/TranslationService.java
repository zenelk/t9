package com.zenelk.t9;

import android.app.Service;
import android.content.Intent;
import android.os.Binder;
import android.os.IBinder;
import android.support.annotation.Nullable;
import android.util.Log;
import android.util.Pair;

import java.io.InputStreamReader;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class TranslationService extends Service {
    private boolean _loaded;
    private TranslationBinder _binder = new TranslationBinder();
    private DatabaseInterface _dbInterface;

    @Override
    public @Nullable IBinder onBind(Intent intent) {
        return _binder;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return START_STICKY;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        if (!_loaded) {
            Log.v("TranslationService", "Starting translation service");
            _dbInterface = new DatabaseInterface(this, "generated_db.db");
            _loaded = true;
            Log.v("TranslationService", "Translation service loaded english sample");
        }
    }

    public String[] translate(String s) {
        if (!_loaded) {
            Log.e("TranslationService", "Cannot translate, english sample is not yet loaded");
            return new String[0];
        }
        List<Pair<String, Integer>> translationResult = _dbInterface.lookup(s);
        if (translationResult == null) {
            return new String[0];
        }
        Collections.sort(translationResult, new Comparator<Pair<String, Integer>>() {
            @Override
            public int compare(Pair<String, Integer> left, Pair<String, Integer> right) {
                return right.second.compareTo(left.second);
            }
        });
        String[] orderedWords = new String[translationResult.size()];
        for (int i = 0; i < orderedWords.length; ++i) {
            orderedWords[i] = translationResult.get(i).first;
        }
        return orderedWords;
    }

    public class TranslationBinder extends Binder {
        public TranslationService getService() {
            return TranslationService.this;
        }
    }
}
