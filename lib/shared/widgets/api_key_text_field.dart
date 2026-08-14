import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 拦截复制动作的 Intent（Ctrl/Cmd+C 时吞掉，防止 key 被复制出去）
class _IgnoreCopyIntent extends Intent {
  const _IgnoreCopyIntent();
}

class _IgnoreCopyAction extends Action<_IgnoreCopyIntent> {
  @override
  Object? invoke(_IgnoreCopyIntent intent) => null;
}

/// API Key 输入框：
/// - 掩码显示（obscureText）
/// - 禁止复制：Ctrl/Cmd+C 拦截、长按菜单不提供复制项
/// - 允许粘贴：长按菜单提供「粘贴」、Ctrl/Cmd+V 放行、输入法粘贴放行
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
  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        // 拦截复制（禁止 key 流出）；粘贴（Ctrl/Cmd+V）放行
        SingleActivator(LogicalKeyboardKey.keyC, control: true): _IgnoreCopyIntent(),
        SingleActivator(LogicalKeyboardKey.keyC, meta: true): _IgnoreCopyIntent(),
      },
      child: Actions(
        actions: {_IgnoreCopyIntent: _IgnoreCopyAction()},
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: widget.controller,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: widget.onChanged,
              // 长按菜单：只提供「粘贴」，不提供复制/全选/剪切
              contextMenuBuilder: (context, editableTextState) {
                return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: editableTextState.contextMenuAnchors,
                  buttonItems: [
                    ContextMenuButtonItem(
                      label: '粘贴',
                      onPressed: () => editableTextState
                          .pasteText(SelectionChangedCause.toolbar),
                    ),
                  ],
                );
              },
              inputFormatters: [
                // key 仅允许字母数字（OpenWeatherMap key 为 32 位 hex）
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                LengthLimitingTextInputFormatter(64),
              ],
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
            if (widget.errorText != null) ...[
              const SizedBox(height: 6),
              Text(
                widget.errorText!,
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
