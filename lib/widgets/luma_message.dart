import 'package:flutter/material.dart';

import '../strings.dart';
import '../styles/app_colors.dart';
import '../styles/dimensions.dart';
import '../styles/text_styles.dart';

/// Displays a Luma-authored message bubble in the conversation feed.
class LumaMessage extends StatelessWidget {
  /// Creates a Luma message bubble.
  const LumaMessage({
    required this.text,
    this.metadata = const <String, dynamic>{},
    super.key,
  });

  /// The message body.
  final String text;

  final Map<String, dynamic> metadata;

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? widgetPayload = _widgetPayload(metadata);
    final bool hasText = text.trim().isNotEmpty;

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
          _AssistantWidgetPayload(payload: widgetPayload),
        ],
      ],
    );
  }
}

class _AssistantWidgetPayload extends StatelessWidget {
  const _AssistantWidgetPayload({required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final String widgetName = payload['widget'] as String? ?? '';
    final Map<String, dynamic> data = Map<String, dynamic>.from(
      (payload['data'] as Map?) ?? const <String, dynamic>{},
    );

    return switch (widgetName) {
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
            (Map<String, dynamic> circle) => Padding(
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
                      circle['name'] as String? ?? Strings.assistantCircleFallbackName,
                      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: Dimensions.xs),
                    Text(
                      '${_intValue(circle['memberCount'])} members · ${circle['city'] as String? ?? ''}',
                      style: AppTextStyles.bodySm,
                    ),
                    if ((circle['vibe'] as String? ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: Dimensions.xs),
                      Text(circle['vibe'] as String, style: AppTextStyles.bodySm),
                    ],
                  ],
                ),
              ),
            ),
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

Map<String, dynamic>? _widgetPayload(Map<String, dynamic> metadata) {
  final dynamic widget = metadata['widget'];
  if (widget is! Map) {
    return null;
  }

  return Map<String, dynamic>.from(widget);
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

int _intValue(dynamic value) {
  return value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;
}
