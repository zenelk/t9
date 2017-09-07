package com.zenelk.t9;

public enum T9Char {
    ABC('2'),
    DEF('3'),
    GHI('4'),
    JKL('5'),
    MNO('6'),
    PQRS('7'),
    TUV('8'),
    WXYZ('9'),
    SHIFT_ABC('2', true),
    SHIFT_DEF('3', true),
    SHIFT_GHI('4', true),
    SHIFT_JKL('5', true),
    SHIFT_MNO('6', true),
    SHIFT_PQRS('7', true),
    SHIFT_TUV('8', true),
    SHIFT_WXYZ('9', true);

    private Character mValue;
    private boolean mShifted;

    T9Char(char value) {
        this(value, false);
    }

    T9Char(char value, boolean shifted) {
        mValue = value;
        mShifted = shifted;
    }

    public char getValue() {
        return mValue;
    }

    public boolean isShifted() {
        return mShifted;
    }
}