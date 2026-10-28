final _placeholderPattern = RegExp(r'\[[^\]]+\]');

class TemplateTextSegment {
  const TemplateTextSegment(this.text);
  final String text;
}

class TemplateFieldSegment {
  const TemplateFieldSegment(this.token);
  final String token;
}

/// Ordered text / field segments for inline rendering.
List<Object> splitTemplate(String body) {
  final out = <Object>[];
  var start = 0;
  for (final match in _placeholderPattern.allMatches(body)) {
    if (match.start > start) {
      out.add(TemplateTextSegment(body.substring(start, match.start)));
    }
    out.add(TemplateFieldSegment(match.group(0)!));
    start = match.end;
  }
  if (start < body.length) {
    out.add(TemplateTextSegment(body.substring(start)));
  }
  return out;
}

/// Unique `[placeholder]` tokens in first-seen order.
List<String> extractPlaceholders(String body) {
  final seen = <String>{};
  final out = <String>[];
  for (final match in _placeholderPattern.allMatches(body)) {
    final token = match.group(0)!;
    if (seen.add(token)) out.add(token);
  }
  return out;
}

/// Replace filled tokens. Empty values leave the `[token]` in place.
String applyPlaceholders(String body, Map<String, String> values) {
  var out = body;
  values.forEach((key, value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    out = out.replaceAll(key, trimmed);
  });
  return out;
}

String placeholderLabel(String token) {
  if (token.length >= 2 && token.startsWith('[') && token.endsWith(']')) {
    return token.substring(1, token.length - 1);
  }
  return token;
}

bool isClientNamePlaceholder(String token) {
  return token.toLowerCase().contains('client name');
}

bool isOptionalNamePlaceholder(String token) {
  final t = token.toLowerCase();
  return t.contains('client name') || t.contains('your name');
}

/// Drop unused client/sign-off tokens so "مرحبا [Client Name]," becomes "مرحبا،".
String stripOptionalNamePlaceholders(String body) {
  var out = body.replaceAll(
    RegExp(r'\[[^\]]*(?:client name|your name)[^\]]*\]', caseSensitive: false),
    '',
  );
  out = out.replaceAll(RegExp(r'مرحبا\s*,'), 'مرحبا،');
  out = out.replaceAll(RegExp(r'Hi\s*,'), 'Hi,');
  out = out.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  return out;
}
