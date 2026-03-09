import 'package:flutter/material.dart';

import '../strings.dart';
import '../styles/app_colors.dart';
import '../styles/dimensions.dart';
import '../styles/text_styles.dart';
import 'quick_reply_chips.dart';

/// Displays a Luma-authored message bubble in the conversation feed.
class LumaMessage extends StatelessWidget {
  /// Creates a Luma message bubble.
  const LumaMessage({
    required this.text,
    this.metadata = const <String, dynamic>{},
    this.onSuggestionSelected,
    super.key,
  });

  /// The message body.
  final String text;

  final Map<String, dynamic> metadata;
  final ValueChanged<String>? onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? activityPayload = _activityPayload(metadata);
    final Map<String, dynamic>? widgetPayload = _widgetPayload(metadata);
    final bool hasText = text.trim().isNotEmpty;

    if (activityPayload != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.auto_awesome, size: 12, color: AppColors.gold),
              const SizedBox(width: Dimensions.xs),
              Text(Strings.shellSectionLabel, style: AppTextStyles.eyebrow),
            ],
          ),
          const SizedBox(height: Dimensions.sm),
          _AssistantActivityStatus(text: text, payload: activityPayload),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.auto_awesome, size: 12, color: AppColors.gold),
            const SizedBox(width: Dimensions.xs),
            Text(Strings.shellSectionLabel, style: AppTextStyles.eyebrow),
          ],
        ),
        if (hasText) ...<Widget>[
          const SizedBox(height: Dimensions.sm),
          Text(
            text,
            style: AppTextStyles.bodyLg.copyWith(
              height: 1.55,
              color: AppColors.ink,
            ),
          ),
        ],
        if (widgetPayload != null) ...<Widget>[
          SizedBox(height: hasText ? Dimensions.md : Dimensions.sm),
          _AssistantWidgetPayload(
            payload: widgetPayload,
            onSuggestionSelected: onSuggestionSelected,
          ),
        ],
      ],
    );
  }
}

class _AssistantActivityStatus extends StatelessWidget {
  const _AssistantActivityStatus({required this.text, required this.payload});

  final String text;
  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final String phase = payload['phase'] as String? ?? 'thinking';
    final List<Map<String, dynamic>> tools = _mapList(payload['tools']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (tools.isNotEmpty && phase == 'writing') ...<Widget>[
          _AssistantToolSummaryChip(tools: tools),
          const SizedBox(height: Dimensions.sm),
        ],
        if (tools.isNotEmpty && phase != 'writing') ...<Widget>[
          Wrap(
            spacing: Dimensions.sm,
            runSpacing: Dimensions.sm,
            children: tools
                .map((Map<String, dynamic> tool) => _AssistantToolChip(tool: tool))
                .toList(growable: false),
          ),
          if (phase != 'tools') const SizedBox(height: Dimensions.sm),
        ],
        if (phase != 'tools') _AssistantStatusBubble(text: text),
      ],
    );
  }
}

class _AssistantToolSummaryChip extends StatelessWidget {
  const _AssistantToolSummaryChip({required this.tools});

  final List<Map<String, dynamic>> tools;

  @override
  Widget build(BuildContext context) {
    final String summary = tools
        .map((Map<String, dynamic> tool) => _toolActivityLabel(tool['name']))
        .where((String label) => label.isNotEmpty)
        .join(', ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F1E8),
        borderRadius: BorderRadius.circular(Dimensions.radiusFull),
        border: Border.all(color: const Color(0xFFB9D7C4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.check_circle, size: 18, color: AppColors.success),
          const SizedBox(width: Dimensions.sm),
          Text(
            '${tools.length} tools called',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.successDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (summary.isNotEmpty) ...<Widget>[
            const SizedBox(width: Dimensions.xs),
            Text(
              '· $summary',
              style: AppTextStyles.bodySm.copyWith(color: AppColors.inkSoft),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssistantToolChip extends StatelessWidget {
  const _AssistantToolChip({required this.tool});

  final Map<String, dynamic> tool;

  @override
  Widget build(BuildContext context) {
    final String status = tool['status'] as String? ?? 'queued';
    final String name = _toolActivityLabel(tool['name']);
    final String? detail = _stringValue(tool['detail']);
    final _ToolChipStyle style = _toolChipStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusFull),
        border: Border.all(color: style.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(style.icon, size: 18, color: style.iconColor),
          const SizedBox(width: Dimensions.sm),
          Text(
            name,
            style: AppTextStyles.bodySm.copyWith(
              color: style.primaryTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (detail != null) ...<Widget>[
            const SizedBox(width: Dimensions.xs),
            Text(
              detail,
              style: AppTextStyles.bodySm.copyWith(color: style.secondaryTextColor),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssistantStatusBubble extends StatelessWidget {
  const _AssistantStatusBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.md, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          const _AssistantPulseDots(),
          const SizedBox(width: Dimensions.sm),
          Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: AppColors.gold,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantPulseDots extends StatelessWidget {
  const _AssistantPulseDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _PulseDot(color: AppColors.gold.withValues(alpha: 0.45)),
        const SizedBox(width: 3),
        _PulseDot(color: AppColors.gold.withValues(alpha: 0.7)),
        const SizedBox(width: 3),
        _PulseDot(color: AppColors.gold),
      ],
    );
  }
}

class _PulseDot extends StatelessWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ToolChipStyle {
  const _ToolChipStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
}

_ToolChipStyle _toolChipStyle(String status) {
  return switch (status) {
    'complete' => const _ToolChipStyle(
        backgroundColor: Color(0xFFE3F1E8),
        borderColor: Color(0xFFB9D7C4),
        icon: Icons.check_circle,
        iconColor: AppColors.success,
        primaryTextColor: AppColors.successDark,
        secondaryTextColor: AppColors.inkSoft,
      ),
    'running' => const _ToolChipStyle(
        backgroundColor: Color(0xFFF1ECE3),
        borderColor: Color(0xFFE0D3BF),
        icon: Icons.auto_awesome,
        iconColor: AppColors.gold,
        primaryTextColor: AppColors.bronze,
        secondaryTextColor: AppColors.inkFaint,
      ),
    _ => const _ToolChipStyle(
        backgroundColor: Color(0xFFF1ECE3),
        borderColor: Color(0xFFE0D3BF),
        icon: Icons.auto_awesome,
        iconColor: AppColors.gold,
        primaryTextColor: AppColors.inkSoft,
        secondaryTextColor: AppColors.inkFaint,
      ),
  };
}

String _toolActivityLabel(dynamic value) {
  return _stringValue(value) ?? '';
}

class _AssistantWidgetPayload extends StatelessWidget {
  const _AssistantWidgetPayload({
    required this.payload,
    this.onSuggestionSelected,
  });

  final Map<String, dynamic> payload;
  final ValueChanged<String>? onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    final String widgetName = payload['widget'] as String? ?? '';
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      (payload['data'] as Map?) ?? const <String, dynamic>{},
    );

    return switch (widgetName) {
      'DinnerCard' => _AssistantPanel(
          title: data['title'] as String? ?? Strings.assistantDinnerFallbackName,
          child: _AssistantDinnerCard(data: data),
        ),
      'CirclesList' => _AssistantPanel(
          title: Strings.assistantMyCirclesTitle,
          child: _AssistantCircleList(circles: _mapList(data['circles'])),
        ),
      'DinnersList' => _AssistantPanel(
          title: data['title'] as String? ?? Strings.assistantDinnersTitle,
          child: _AssistantDinnerList(dinners: _mapList(data['dinners'])),
        ),
      'CircleDetail' => _AssistantPanel(
          title: data['name'] as String? ?? Strings.assistantCircleDetailTitle,
          child: _AssistantCircleDetail(data: data),
        ),
      'SuggestionChips' => _AssistantPanel(
          title: data['title'] as String? ?? Strings.assistantSuggestionsTitle,
          child: _AssistantSuggestionChips(
            prompt: data['prompt'] as String? ?? '',
            suggestions: _mapSuggestionList(data['options']),
            onSuggestionSelected: onSuggestionSelected,
          ),
        ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _AssistantPanel extends StatelessWidget {
  const _AssistantPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppTextStyles.h3.copyWith(fontSize: 18)),
          const SizedBox(height: Dimensions.sm),
          child,
        ],
      ),
    );
  }
}

class _AssistantCircleList extends StatelessWidget {
  const _AssistantCircleList({required this.circles});

  final List<Map<String, dynamic>> circles;

  @override
  Widget build(BuildContext context) {
    if (circles.isEmpty) {
      return Text(
        Strings.assistantNoCirclesMessage,
        style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
      );
    }

    return Column(
      children: circles
          .map(
            (Map<String, dynamic> circle) {
              final String name = _stringValue(circle['name'])
                  ?? _stringValue(circle['inviteCode'])
                  ?? Strings.assistantCircleFallbackName;
              final String? city = _stringValue(circle['city']);
              final String? vibe = _stringValue(circle['vibe']);
              final String? nextPairingLabel = _stringValue(circle['nextPairingLabel']);
              final String? pairingFrequency = _stringValue(circle['pairingFrequency']);
              final String memberLabel = '${_intValue(circle['memberCount'])} members';
              final String secondaryLine = <String>[
                memberLabel,
                if (city != null) city else if (pairingFrequency != null) pairingFrequency,
              ].join(' · ');

              return Padding(
                padding: const EdgeInsets.only(bottom: Dimensions.sm),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.md),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: Dimensions.xs),
                      Text(secondaryLine, style: AppTextStyles.bodySm),
                      if (vibe != null) ...<Widget>[
                        const SizedBox(height: Dimensions.xs),
                        Text(vibe, style: AppTextStyles.bodySm),
                      ],
                      if (nextPairingLabel != null) ...<Widget>[
                        const SizedBox(height: Dimensions.xs),
                        Text(nextPairingLabel, style: AppTextStyles.bodySm),
                      ],
                    ],
                  ),
                ),
              );
            },
          )
          .toList(growable: false),
    );
  }
}

class _AssistantDinnerList extends StatelessWidget {
  const _AssistantDinnerList({required this.dinners});

  final List<Map<String, dynamic>> dinners;

  @override
  Widget build(BuildContext context) {
    if (dinners.isEmpty) {
      return Text(
        Strings.assistantNoDinnersMessage,
        style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
      );
    }

    return Column(
      children: dinners
          .map(
            (Map<String, dynamic> dinner) => Padding(
              padding: const EdgeInsets.only(bottom: Dimensions.sm),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Dimensions.md),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      dinner['title'] as String? ?? Strings.assistantDinnerFallbackName,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: Dimensions.xs),
                    Text(
                      '${dinner['dateLabel'] as String? ?? ''} · ${dinner['timeLabel'] as String? ?? ''}',
                      style: AppTextStyles.bodySm,
                    ),
                    const SizedBox(height: Dimensions.xs),
                    Text(
                      '${dinner['venue'] as String? ?? ''} · ${dinner['city'] as String? ?? ''}',
                      style: AppTextStyles.bodySm,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _AssistantDinnerCard extends StatelessWidget {
  const _AssistantDinnerCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final String title = _stringValue(data['title']) ?? Strings.assistantDinnerFallbackName;
    final String? circleName = _stringValue(data['circleName']);
    final String? dateLabel = _stringValue(data['dateLabel']);
    final String? timeLabel = _stringValue(data['timeLabel']);
    final String? venue = _stringValue(data['venue']);
    final String? city = _stringValue(data['city']);
    final String whenLine = <String>[
      if (dateLabel != null) dateLabel,
      if (timeLabel != null) timeLabel,
    ].join(' · ');
    final String whereLine = <String>[
      if (venue != null) venue,
      if (city != null) city,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (circleName != null)
          Text(
            circleName,
            style: AppTextStyles.eyebrow.copyWith(color: AppColors.gold),
          ),
        if (circleName != null) const SizedBox(height: Dimensions.xs),
        Text(
          title,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
        if (whenLine.isNotEmpty) ...<Widget>[
          const SizedBox(height: Dimensions.xs),
          Text(whenLine, style: AppTextStyles.bodySm),
        ],
        if (whereLine.isNotEmpty) ...<Widget>[
          const SizedBox(height: Dimensions.xs),
          Text(whereLine, style: AppTextStyles.bodySm),
        ],
      ],
    );
  }
}

class _AssistantCircleDetail extends StatelessWidget {
  const _AssistantCircleDetail({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> members = _mapList(data['members']);
    final List<Map<String, dynamic>> memories = _mapList(data['memories']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if ((data['vibe'] as String? ?? '').isNotEmpty)
          Text(data['vibe'] as String, style: AppTextStyles.body.copyWith(color: AppColors.inkSoft)),
        if ((data['nextPairingLabel'] as String? ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: Dimensions.sm),
          Text(data['nextPairingLabel'] as String, style: AppTextStyles.bodySm),
        ],
        const SizedBox(height: Dimensions.sm),
        Text(
          '${_intValue(data['memberCount'])} members · ${data['visibility'] as String? ?? ''}',
          style: AppTextStyles.bodySm,
        ),
        if ((data['inviteCode'] as String? ?? '').isNotEmpty) ...<Widget>[
          const SizedBox(height: Dimensions.xs),
          Text(
            '${Strings.assistantInviteCodeLabel}: ${data['inviteCode'] as String}',
            style: AppTextStyles.bodySm,
          ),
        ],
        if (members.isNotEmpty) ...<Widget>[
          const SizedBox(height: Dimensions.md),
          Text(
            members
                .map(
                  (Map<String, dynamic> member) =>
                      member['firstName'] as String? ?? Strings.assistantMemberFallbackName,
                )
                .join(', '),
            style: AppTextStyles.bodySm,
          ),
        ],
        if (memories.isNotEmpty) ...<Widget>[
          const SizedBox(height: Dimensions.sm),
          Text(
            memories
                .map((Map<String, dynamic> memory) => memory['caption'] as String? ?? '')
                .where((String caption) => caption.isNotEmpty)
                .join(' · '),
            style: AppTextStyles.bodySm,
          ),
        ],
      ],
    );
  }
}

class _AssistantSuggestionChips extends StatelessWidget {
  const _AssistantSuggestionChips({
    required this.prompt,
    required this.suggestions,
    this.onSuggestionSelected,
  });

  final String prompt;
  final List<Map<String, dynamic>> suggestions;
  final ValueChanged<String>? onSuggestionSelected;

  @override
  Widget build(BuildContext context) {
    final List<String> labels = suggestions
        .map((Map<String, dynamic> suggestion) => suggestion['label'] as String? ?? '')
        .where((String label) => label.isNotEmpty)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (prompt.isNotEmpty)
          Text(
            prompt,
            style: AppTextStyles.body.copyWith(color: AppColors.inkSoft),
          ),
        if (prompt.isNotEmpty && labels.isNotEmpty) const SizedBox(height: Dimensions.sm),
        if (labels.isNotEmpty)
          QuickReplyChips(
            options: labels,
            onSelected: (String label) {
              final Map<String, dynamic> suggestion = suggestions.firstWhere(
                (Map<String, dynamic> item) => item['label'] == label,
                orElse: () => <String, dynamic>{'message': label},
              );
              final String message = suggestion['message'] as String? ?? label;
              onSuggestionSelected?.call(message);
            },
          ),
      ],
    );
  }
}

Map<String, dynamic>? _widgetPayload(Map<String, dynamic> metadata) {
  final dynamic widget = metadata['widget'];
  if (widget is! Map) {
    return null;
  }

  return Map<String, dynamic>.from(widget);
}

Map<String, dynamic>? _activityPayload(Map<String, dynamic> metadata) {
  if (metadata['activity'] != true) {
    return null;
  }

  final dynamic activityState = metadata['activityState'];
  if (activityState is! Map) {
    return null;
  }

  return Map<String, dynamic>.from(activityState);
}

List<Map<String, dynamic>> _mapList(dynamic value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }

  return value
      .whereType<Map>()
      .map((Map item) => Map<String, dynamic>.from(item))
      .toList(growable: false);
}

List<Map<String, dynamic>> _mapSuggestionList(dynamic value) {
  return _mapList(value)
      .where(
        (Map<String, dynamic> item) =>
            (item['label'] as String? ?? '').isNotEmpty &&
            (item['message'] as String? ?? '').isNotEmpty,
      )
      .toList(growable: false);
}

int _intValue(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }

  final String? normalized = _stringValue(value);
  if (normalized == null) {
    return 0;
  }

  return int.tryParse(normalized) ?? double.tryParse(normalized)?.round() ?? 0;
}

String? _stringValue(dynamic value) {
  if (value == null) {
    return null;
  }

  final String normalized = value.toString().trim();
  return normalized.isEmpty ? null : normalized;
}
