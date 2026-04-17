package com.kernelkraft.punjabi_keyboard.ime

import android.inputmethodservice.InputMethodService
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.InputMethodManager

class PunjabiInputMethodService : InputMethodService(), KeyboardView.Listener, EmojiView.Listener {

    private lateinit var root: android.widget.FrameLayout
    private lateinit var keyboardView: KeyboardView
    private var emojiView: EmojiView? = null

    override fun onCreateInputView(): View {
        root = android.widget.FrameLayout(this)
        keyboardView = KeyboardView(this, this)
        root.addView(keyboardView)
        return root
    }

    // --- KeyboardView.Listener -------------------------------------------

    override fun onCommit(text: String) {
        currentInputConnection?.commitText(text, 1)
    }

    override fun onBackspace() {
        val ic = currentInputConnection ?: return
        val selected = ic.getSelectedText(0)
        if (!selected.isNullOrEmpty()) {
            ic.commitText("", 1)
        } else {
            // Delete one code-point (handles surrogate pairs + combining marks).
            val before = ic.getTextBeforeCursor(2, 0) ?: ""
            val del = if (before.length >= 2 && Character.isSurrogatePair(before[0], before[1])) 2 else 1
            ic.deleteSurroundingText(del, 0)
        }
    }

    override fun onEnter() {
        val ic = currentInputConnection ?: return
        val editor = currentInputEditorInfo
        val action = editor.imeOptions and android.view.inputmethod.EditorInfo.IME_MASK_ACTION
        if (action != android.view.inputmethod.EditorInfo.IME_ACTION_NONE &&
            action != android.view.inputmethod.EditorInfo.IME_ACTION_UNSPECIFIED
        ) {
            ic.performEditorAction(action)
        } else {
            ic.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER))
            ic.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_ENTER))
        }
    }

    override fun onSwitchLanguage() {
        val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
        imm.showInputMethodPicker()
    }

    override fun onShowEmoji() {
        val view = EmojiView(this, this)
        emojiView = view
        root.removeAllViews()
        root.addView(view)
    }

    // --- EmojiView.Listener ----------------------------------------------

    override fun onBackToKeyboard() {
        root.removeAllViews()
        root.addView(keyboardView)
        emojiView = null
    }
}
