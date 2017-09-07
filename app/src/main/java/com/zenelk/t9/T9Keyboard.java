package com.zenelk.t9;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.inputmethodservice.InputMethodService;
import android.inputmethodservice.Keyboard;
import android.inputmethodservice.KeyboardView;
import android.os.IBinder;
import android.text.InputType;
import android.util.Log;
import android.view.KeyEvent;
import android.view.View;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;

import java.util.ArrayList;
import java.util.List;

public class T9Keyboard extends InputMethodService
        implements KeyboardView.OnKeyboardActionListener {
    private static final String TAG = "T9Keyboard";

    private KeyboardView mKeyboardView;
    private Keyboard mKeyboard;
    private StringBuilder mComposing = new StringBuilder();
    private TranslationService _translationService;
    private String mWordSeparators;
    private int mCurrentTranslationIndex = 0;
    private long mLastShiftTime;
    private boolean mCapsLock;
    private boolean mDeletePressed;

    private T9Manager mT9;

    @Override
    public View onCreateInputView() {
        mKeyboardView = (KeyboardView)getLayoutInflater().inflate(R.layout.keyboard, null);
        mKeyboard = new Keyboard(this, R.xml.t9);
        mKeyboardView.setPreviewEnabled(false);
        mKeyboardView.setKeyboard(mKeyboard);
        mKeyboardView.setOnKeyboardActionListener(this);
        mKeyboardView.setShifted(true);
        mWordSeparators = getResources().getString(R.string.word_separators);
        mT9 = new T9Manager(this);
        mT9.append(getCurrentInputConnection(), T9Char.SHIFT);
        mT9.append(getCurrentInputConnection(), T9Char.ABC);
        doBindService();
        return mKeyboardView;
    }


    @Override
    public void onDestroy() {
        super.onDestroy();
        Log.v("T9Keyboard", "onDestroy");
        doUnbindService();
    }

    @Override
    public void onStartInput(EditorInfo attribute, boolean restarting) {
        super.onStartInput(attribute, restarting);
        Log.v(TAG, "onStartInput");
        resetWordState();
    }

    @Override
    public void onFinishInput() {
        super.onFinishInput();
        Log.v(TAG, "onFinishInput");
        resetWordState();
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {
        Log.v(TAG, "onKeyDown");
        switch (keyCode) {
            case KeyEvent.KEYCODE_BACK:
                if (event.getRepeatCount() == 0 && mKeyboardView != null) {
                    if (mKeyboardView.handleBack()) {
                        return true;
                    }
                }
                break;
            case KeyEvent.KEYCODE_DEL:
                if (mComposing.length() > 0) {
                    onKey(Keyboard.KEYCODE_DELETE, null);
                    return true;
                }
                break;
            case KeyEvent.KEYCODE_ENTER:
                // Let the text editor handle this
                return false;
            default:
                break;
        }
        return super.onKeyDown(keyCode, event);
    }

    // Implementation of KeyboardViewListener
    @Override
    public void onKey(int primaryCode, int[] keyCodes) {
        if (isWordSeparator((char) primaryCode)) {
            handleWordSeparator(primaryCode);
        }
        else if (primaryCode == Keyboard.KEYCODE_DELETE) {
            handleBackspace();
        }
          else if (primaryCode == Keyboard.KEYCODE_SHIFT) {
            handleShift();
        }
        else if (primaryCode == Keyboard.KEYCODE_CANCEL) {
            handleClose();
//            return;
//        }
//          else if (primaryCode == LatinKeyboardView.KEYCODE_LANGUAGE_SWITCH) {
//            handleLanguageSwitch();
//            return;
//        }
//          else if (primaryCode == LatinKeyboardView.KEYCODE_OPTIONS) {
//             Show a menu or somethin'
//        }
//          else if (primaryCode == Keyboard.KEYCODE_MODE_CHANGE
//                && mInputView != null) {
//            Keyboard current = mInputView.getKeyboard();
//            if (current == mSymbolsKeyboard || current == mSymbolsShiftedKeyboard) {
//                setLatinKeyboard(mQwertyKeyboard);
//            }
//              else {
//                setLatinKeyboard(mSymbolsKeyboard);
//                mSymbolsKeyboard.setShifted(false);
//            }
        }
        else {
            handleCharacter(primaryCode, keyCodes);
        }
    }

    private void handleWordSeparator(int primaryCode) {
        if (mComposing.length() > 0) {
            commitTyped(getCurrentInputConnection());
        }
        CharSequence textBeforeCursor = getCurrentInputConnection().getTextBeforeCursor(1, 0);
        if (textBeforeCursor.length() == 1 && textBeforeCursor.charAt(0) == ' ') {
            getCurrentInputConnection().deleteSurroundingText(1, 0);
            sendKey((int) '.');
            sendKey(primaryCode);
            mKeyboardView.setShifted(true);
        }
        else {
            sendKey(primaryCode);
            updateShiftKeyState(getCurrentInputEditorInfo());
        }
    }

    private boolean isWordSeparator(char primaryCode) {
        return mWordSeparators.contains(String.valueOf(primaryCode));
    }

    @Override
    public void onUpdateSelection(int oldSelStart, int oldSelEnd, int newSelStart, int newSelEnd, int candidatesStart, int candidatesEnd) {
        super.onUpdateSelection(oldSelStart, oldSelEnd, newSelStart, newSelEnd, candidatesStart, candidatesEnd);
        if (mComposing.length() > 0 && (newSelStart != candidatesEnd || newSelEnd != candidatesEnd)) {
            resetWordState();
            InputConnection ic = getCurrentInputConnection();
            if (ic != null) {
                ic.finishComposingText();
            }
        }
    }

    @Override
    public void onPress(int primaryCode) {
        Log.v(TAG, "onPress: " + primaryCode);
        mDeletePressed = primaryCode == Keyboard.KEYCODE_DELETE;
    }

    @Override
    public void onRelease(int primaryCode) {
    }

    @Override
    public void onText(CharSequence text) {
        InputConnection ic = getCurrentInputConnection();
        if (ic == null) return;
        ic.beginBatchEdit();
        if (mComposing.length() > 0) {
            commitTyped(ic);
        }
        ic.commitText(text, 0);
        ic.endBatchEdit();
        updateShiftKeyState(getCurrentInputEditorInfo());
    }

    @Override
    public void swipeDown() {
        Log.v(TAG, "swipeDown");
        handleClose();
    }

    @Override
    public void swipeLeft() {
        Log.v(TAG, "swipeLeft");
        if (mDeletePressed) {
            InputConnection currentInputConnection = getCurrentInputConnection();
            int readBack = 1;
            int lastTextLength = -1;
            CharSequence textBeforeCursor;
            while (true) {
                textBeforeCursor = currentInputConnection.getTextBeforeCursor(readBack, 0);
                if (textBeforeCursor.length() < 1) {
                    Log.v(TAG, "No text");
                    return;
                }
                if (textBeforeCursor.length() == lastTextLength) {
                    Log.v(TAG, "No more text, deleting back " + readBack);
                    break;
                }
                lastTextLength = textBeforeCursor.length();
                char first = textBeforeCursor.charAt(0);
                CharSequence firstSequence = new String(new char[] { first });
                if (mWordSeparators.contains(firstSequence)) {
                    Log.v(TAG, "Deleting back " + readBack);
                    break;
                }
                ++readBack;
            }
            currentInputConnection.deleteSurroundingText(readBack, 0);
            resetWordState();
        }
    }

    @Override
    public void swipeRight() {
    }

    @Override
    public void swipeUp() {
    }

    private void insertText(CharSequence text) {
        getCurrentInputConnection().commitText(text, 1);
    }

    private void clearText() {
        getCurrentInputConnection().commitText("", 0);
    }

    private void keyDownUp(int keyEventCode) {
        getCurrentInputConnection().sendKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN, keyEventCode));
        getCurrentInputConnection().sendKeyEvent(new KeyEvent(KeyEvent.ACTION_UP, keyEventCode));
    }

    private void sendKey(int keyCode) {
        switch (keyCode) {
            case '\n':
                keyDownUp(KeyEvent.KEYCODE_ENTER);
                break;
            default:
                if (keyCode >= '0' && keyCode <= '9') {
                    keyDownUp(keyCode - '0' + KeyEvent.KEYCODE_0);
                }
                else {
                    insertText(String.valueOf((char) keyCode));
                    if (getCurrentInputConnection().getTextBeforeCursor(2, 0).equals(". ")) {
                        mKeyboardView.setShifted(true);
                    }
                }
                break;
        }
    }

    private void commitTyped(InputConnection inputConnection) {
        if (mComposing.length() > 0) {
            setComposingTextAsTranslation(true);
            resetWordState();
        }
    }

    private void handleClose() {
        commitTyped(getCurrentInputConnection());
        requestHideSelf(0);
        mKeyboardView.closing();
    }

    private void handleCharacter(int primaryCode, int[] keyCodes) {
        if (isInputViewShown()) {
            if (mKeyboardView.isShifted()) {
                primaryCode = Character.toUpperCase(primaryCode);
            }
        }
        if (Character.isDigit(primaryCode)) {
            if (primaryCode == '1') {
                if (++mCurrentTranslationIndex >= _translationService.translate(mComposing.toString()).length) {
                    mCurrentTranslationIndex = 0;
                }
            }
            else {
                mComposing.append((char) primaryCode);
            }
            setComposingTextAsTranslation(false);
            updateShiftKeyState(getCurrentInputEditorInfo());
        }
        else {
            insertText(String.valueOf((char) primaryCode));
        }
    }

    private void setComposingTextAsTranslation(boolean commit) {
        String[] translations = _translationService.translate(mComposing.toString());
        if (translations.length > 0) {
            String translation = translations[mCurrentTranslationIndex];
            StringBuilder translationShifted = new StringBuilder();
            char[] translationChars = translation.toCharArray();
            for (int i = 0; i < translation.length(); ++i) {
//                translationShifted.append(mCapitalizedLetterStates.get(i) ? Character.toUpperCase(translationChars[i]) : translationChars[i]);
            }
            translation = translationShifted.toString();
            if (commit) {
                insertText(translation);
            }
            else {
                getCurrentInputConnection().setComposingText(translation, 1);
            }
        }
        else {
            getCurrentInputConnection().setComposingText(mComposing.toString(), 1);
        }
    }

    private void handleBackspace() {
        final int length = mComposing.length();
        if (length > 1) {
            mCurrentTranslationIndex = 0;
            if (Character.isUpperCase(mComposing.charAt(length - 1))) {
                mKeyboard.setShifted(true);
            }
            mComposing.delete(length - 1, length);
            setComposingTextAsTranslation(false);
        }
        else if (length > 0) {
            resetWordState();
            clearText();
        }
        else {
            keyDownUp(KeyEvent.KEYCODE_DEL);
        }
        updateShiftKeyState(getCurrentInputEditorInfo());
    }

    private void handleShift() {
        if (mKeyboardView == null) {
            return;
        }
        checkToggleCapsLock();
        mKeyboardView.setShifted(mCapsLock || !mKeyboardView.isShifted());
//        else if (currentKeyboard == mSymbolsKeyboard) {
//            mSymbolsKeyboard.setShifted(true);
//            setLatinKeyboard(mSymbolsShiftedKeyboard);
//            mSymbolsShiftedKeyboard.setShifted(true);
//        }
//        else if (currentKeyboard == mSymbolsShiftedKeyboard) {
//            mSymbolsShiftedKeyboard.setShifted(false);
//            setLatinKeyboard(mSymbolsKeyboard);
//            mSymbolsKeyboard.setShifted(false);
//        }
    }

    private void checkToggleCapsLock() {
        long now = System.currentTimeMillis();
        if (mLastShiftTime + 800 > now) {
            mCapsLock = !mCapsLock;
            mLastShiftTime = 0;
        } else {
            mLastShiftTime = now;
        }
    }

    private void updateShiftKeyState(EditorInfo attr) {
        // If there is no more text in the field, then reset the shift state.
        if (getCurrentInputConnection().getTextBeforeCursor(1, 0).equals("")) {
            mKeyboardView.setShifted(true);
            return;
        }
        if (attr != null && mKeyboardView != null) {
            int caps = 0;
            EditorInfo ei = getCurrentInputEditorInfo();
            if (ei != null && ei.inputType != InputType.TYPE_NULL) {
                caps = getCurrentInputConnection().getCursorCapsMode(attr.inputType);
            }
            mKeyboardView.setShifted(mCapsLock || caps != 0);
        }
    }

    private void resetWordState() {
        mCurrentTranslationIndex = 0;
        mComposing.setLength(0);
    }

    /**
     * ServiceConnection
     */

    private ServiceConnection _translationServiceConnection = new ServiceConnection() {
        public void onServiceConnected(ComponentName className, IBinder service) {
            // This is called when the connection with the service has been
            // established, giving us the service object we can use to
            // interact with the service.  Because we have bound to a explicit
            // service that we know is running in our own process, we can
            // cast its IBinder to a concrete class and directly access it.
            _translationService = ((TranslationService.TranslationBinder)service).getService();
        }

        public void onServiceDisconnected(ComponentName className) {
            // This is called when the connection with the service has been
            // unexpectedly disconnected -- that is, its process crashed.
            // Because it is running in our same process, we should never
            // see this happen.
            _translationService = null;
        }
    };

    private void doBindService() {
        // Establish a connection with the service.  We use an explicit
        // class name because we want a specific service implementation that
        // we know will be running in our own process (and thus won't be
        // supporting component replacement by other applications).
//        startService(new Intent(this, TranslationService.class));
        startService(new Intent(this, TranslationService.class));
        bindService(new Intent(this, TranslationService.class), _translationServiceConnection, Context.BIND_ABOVE_CLIENT);
    }

    private void doUnbindService() {
        if (_translationService != null) {
            // Detach our existing connection.
            unbindService(_translationServiceConnection);
        }
    }
}