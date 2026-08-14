import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 拦截粘贴动作的 Intent（Ctrl/Cmd+V 时吞掉，不执行粘贴）
class _IgnorePasteIntent extends Intent {
  const _IgnorePasteIntent();
}

class _IgnorePasteAction extends Action<_IgnorePasteIntent> {
  @override
  Object? invoke(_IgnorePasteIntent intent) => null;
}

/// API Key 输入框：
/// - 掩码显示（obscureText）
/// - 不可选中/复制（enableInteractiveSelection=false + 无长按菜单）
/// - 不可粘贴（长按菜单、Ctrl/Cmd+V、IME 大段粘贴回滚三重拦截）
/// - 仅允许 key 字符集（字母数字），限制长度
class ApiKeyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const ApiKeyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.errorText,
  });

  @override
  State<ApiKeyTextField> createState() => _ApiKeyTextFieldState();
}

class _ApiKeyTextFieldState extends State<ApiKeyTextField> {
  String _lastText = '';
  bool _pasteRejected = false;

  @override
  void initState() {
    super.initState();
    _lastText = widget.controller.text;
  }

  void _onChanged(String text) {
    // 疑似粘贴（单次插入超过 4 个字符）：回滚并拒绝
    if (text.length > _lastText.length + 4) {
      widget.controller.text = _lastText;
      widget.controller.selection =
          TextSelection.collapsed(offset: _lastText.length);
      setState(() => _pasteRejected = true);
      return;
    }
    _lastText = text;
    setState(() => _pasteRejected = false);
    widget.onChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyV, control: true): _IgnorePasteIntent(),
        SingleActivator(LogicalKeyboardKey.keyV, meta: true): _IgnorePasteIntent(),
      },
      child: Actions(
        actions: {_IgnorePasteIntent: _IgnorePasteAction()},
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.controller,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              enableInteractiveSelection: false,
              contextMenuBuilder: (context, editableTextState) =>
                  const SizedBox.shrink(),
              inputFormatters: [
                // key 仅允许字母数字（OpenWeatherMap key 为 32 位 hex）
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                LengthLimitingTextInputFormatter(64),
              ],
              onChanged: _onChanged,
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 13,
                color: Color(0xFFE2E8F0),
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 11,
                  color: Color(0xFF475569),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0x3300F0FF), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF00F0FF), width: 0.8),
                ),
              ),
            ),
            if (_pasteRejected || widget.errorText != null) ...[
              const SizedBox(height: 6),
              Text(
                _pasteRejected ? '不允许粘贴，请手动输入' : (widget.errorText ?? ''),
                style: const TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 9,
                  color: Color(0xFFFF006E),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
