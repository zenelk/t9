package com.zenelk.t9;

import android.content.Context;
import android.util.Pair;
import android.view.inputmethod.InputConnection;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class T9Manager {
    private DatabaseInterface mDb;
    private List<T9Char> mComposing = new ArrayList<>();
    private int mTranslationIndex = 0;

    public T9Manager(Context context) {
        mDb = new DatabaseInterface(context, "generated_db.db");
    }

    public void append(InputConnection ic, T9Char t9c) {
        mComposing.add(t9c);
        mTranslationIndex = 0;
        updateComposingText(ic);
    }

    public void nextTranslation(InputConnection ic) {
        ++mTranslationIndex;
        updateComposingText(ic);
    }

    public void deleteWord() {}

    public void backspace() {}

    public void finishWord() {}

    private void updateComposingText(InputConnection ic) {
        String[] translations = getComposingTranslations();
        if (translations.length > 0) {
            if (mTranslationIndex >= translations.length) {
                mTranslationIndex = 0;
            }
            ic.setComposingText(translations[mTranslationIndex], 1);
        }
        else {
            ic.setComposingText(getComposingT9(), 1);
        }
    }

    private String[] getComposingTranslations() {
        String composingT9 = getComposingT9();
        List<Pair<String, Integer>> lookupResult = mDb.lookup(composingT9);
        if (lookupResult == null) {
            return new String[0];
        }
        Collections.sort(lookupResult, new Comparator<Pair<String, Integer>>() {
            @Override
            public int compare(Pair<String, Integer> left, Pair<String, Integer> right) {
                return right.second.compareTo(left.second);
            }
        });
        String[] result = new String[lookupResult.size()];
        for (int i = 0; i < result.length; ++i) {
            result[i] = lookupResult.get(i).first;
        }
        return result;
    }

    private String getComposingT9() {
        StringBuilder sb = new StringBuilder();
        for (T9Char t9c : mComposing) {
            char value = t9c.getValue();
            if (t9c.isShifted()) {
                value = Character.toUpperCase(value);
            }
            sb.append(value);
        }
        return sb.toString();
    }
}
