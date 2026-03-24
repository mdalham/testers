import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:testers/models/room_model.dart';

const _blue = Color(0xFF1565C0);
const _deepBlue = Color(0xFF1A237E);
const _orange = Color(0xFFFF9800);
const _green = Color(0xFF2E7D32);






void showTestDetailSheet(
  BuildContext context, {
  required String testerUid,
  required String testerName,
  required String screenshotUrl,
  required DateTime submittedAt,
  required AppDetails appDetails,
  String? issueType,
  String? reportText,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: true,
    builder: (_) => _ProofDetailSheet(
      testerUid: testerUid,
      testerName: testerName,
      screenshotUrl: screenshotUrl,
      submittedAt: submittedAt,
      appDetails: appDetails,
      issueType: issueType,
      reportText: reportText,
    ),
  );
}





class _ProofDetailSheet extends StatelessWidget {
  const _ProofDetailSheet({
    required this.testerUid,
    required this.testerName,
    required this.screenshotUrl,
    required this.submittedAt,
    required this.appDetails,
    this.issueType,
    this.reportText,
  });

  final String testerUid;
  final String testerName;
  final String screenshotUrl;
  final DateTime submittedAt;
  final AppDetails appDetails;
  final String? issueType;
  final String? reportText;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.96,
      snap: true,
      snapSizes: const [0.55, 0.96],
      builder: (context, scrollController) {
        return _SheetBody(
          scrollController: scrollController,
          testerUid: testerUid,
          testerName: testerName,
          screenshotUrl: screenshotUrl,
          submittedAt: submittedAt,
          appDetails: appDetails,
          issueType: issueType,
          reportText: reportText,
        );
      },
    );
  }
}





class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.scrollController,
    required this.testerUid,
    required this.testerName,
    required this.screenshotUrl,
    required this.submittedAt,
    required this.appDetails,
    this.issueType,
    this.reportText,
  });

  final ScrollController scrollController;
  final String testerUid;
  final String testerName;
  final String screenshotUrl;
  final DateTime submittedAt;
  final AppDetails appDetails;
  final String? issueType;
  final String? reportText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: cs.outline, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.18),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _blue.withOpacity(0.25)),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    size: 18,
                    color: _blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reports',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a').format(submittedAt),
                        style: tt.labelSmall?.copyWith(color: cs.onPrimary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon:  Icon(Icons.close_rounded,color: cs.onSurface,),
                  style: IconButton.styleFrom(backgroundColor: Colors.transparent),
                ),
              ],
            ),
          ),

          Divider(height: 24, thickness: 1, color: cs.outline),

          
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              children: [
                
                _SectionCard(
                  icon: Icons.smartphone_rounded,
                  title: 'App Information',
                  child: _AppInfoTile(
                    appDetails: appDetails,
                    testerName: testerName,
                  ),
                ),
                const SizedBox(height: 12),

                
                _SectionCard(
                  icon: Icons.photo_rounded,
                  title: 'Screenshot',
                  child: _ScreenshotSection(
                    screenshotUrl: screenshotUrl,
                    testerUid: testerUid,
                    submittedAt: submittedAt,
                    appDetails: appDetails,
                    testerName: testerName,
                    issueType: issueType,
                    reportText: reportText,
                  ),
                ),
                const SizedBox(height: 12),

                
                _SectionCard(
                  icon: Icons.bug_report_rounded,
                  title: 'Report',
                  child: _BugReportSection(
                    issueType: issueType,
                    reportText: reportText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}





class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Icon(icon, size: 15, color: _blue),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _blue,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: cs.outline),
          child,
        ],
      ),
    );
  }
}





class _AppInfoTile extends StatelessWidget {
  const _AppInfoTile({required this.appDetails, required this.testerName});

  final AppDetails appDetails;
  final String testerName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 56,
              height: 56,
              color: cs.surfaceContainerHigh,
              child: appDetails.iconUrl.isNotEmpty
                  ? Image.network(
                      appDetails.iconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _IconFallback(name: appDetails.appName),
                    )
                  : _IconFallback(name: appDetails.appName),
            ),
          ),
          const SizedBox(width: 14),

          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appDetails.appName,
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '@$testerName',
                        style: tt.bodySmall?.copyWith(color: cs.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 12,
                      color: cs.onSurface,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        appDetails.packageName,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}





class _ScreenshotSection extends StatelessWidget {
  const _ScreenshotSection({
    required this.screenshotUrl,
    required this.testerUid,
    required this.submittedAt,
    required this.appDetails,
    required this.testerName,
    this.issueType,
    this.reportText,
  });

  final String screenshotUrl;
  final String testerUid;
  final DateTime submittedAt;
  final AppDetails appDetails;
  final String testerName;
  final String? issueType;
  final String? reportText;

  void _openFullScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullScreenshotView(
          screenshotUrl: screenshotUrl,
          testerUid: testerUid,
          testerName: testerName,
          submittedAt: submittedAt,
          appDetails: appDetails,
          issueType: issueType,
          reportText: reportText,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (screenshotUrl.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.image_not_supported_rounded,
                size: 36,
                color: cs.onSurfaceVariant.withOpacity(0.4),
              ),
              const SizedBox(height: 8),
              Text(
                'No screenshot provided',
                style: tt.bodySmall?.copyWith(color: cs.onPrimary),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Hero(
          tag: 'sheet_screenshot_${testerUid}_$submittedAt',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                  width: .infinity,
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: Image.network(
                      screenshotUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: cs.surfaceContainerHigh,
                        child: Icon(
                          Icons.broken_image_rounded,
                          size: 48,
                          color: cs.onSurfaceVariant.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ),
                
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.65),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.zoom_in_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tap to view full screen',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}





class _BugReportSection extends StatelessWidget {
  const _BugReportSection({this.issueType, this.reportText});

  final String? issueType;
  final String? reportText;

  static const _issueMap = {
    'bug': (icon: Icons.bug_report_rounded, color: Colors.red, label: 'Bug'),
    'ui': (
      icon: Icons.design_services_rounded,
      color: _blue,
      label: 'UI Problem',
    ),
    'crash': (
      icon: Icons.warning_amber_rounded,
      color: _orange,
      label: 'App Crash',
    ),
    'other': (
      icon: Icons.more_horiz_rounded,
      color: Colors.grey,
      label: 'Other',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final hasReport = reportText != null && reportText!.isNotEmpty;
    final hasIssue = issueType != null;

    if (!hasIssue && !hasReport) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 18,
              color: _green.withOpacity(0.7),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No issues were reported by the tester.',
                style: tt.bodySmall?.copyWith(color: cs.onPrimary, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          if (hasIssue) ...[
            _IssueBadge(type: issueType!),
            if (hasReport) const SizedBox(height: 12),
          ],

          
          if (hasReport)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outline),
              ),
              child: Text(
                reportText!,
                style: tt.bodySmall?.copyWith(height: 1.6),
              ),
            ),
        ],
      ),
    );
  }
}





class _IssueBadge extends StatelessWidget {
  const _IssueBadge({required this.type});
  final String type;

  static const _map = {
    'bug': (icon: Icons.bug_report_rounded, color: Colors.red, label: 'Bug'),
    'ui': (
      icon: Icons.design_services_rounded,
      color: _blue,
      label: 'UI Problem',
    ),
    'crash': (
      icon: Icons.warning_amber_rounded,
      color: _orange,
      label: 'App Crash',
    ),
    'other': (
      icon: Icons.more_horiz_rounded,
      color: Colors.grey,
      label: 'Other',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final info = _map[type];
    final color = info?.color ?? Colors.grey;
    final label = info?.label ?? type;
    final icon = info?.icon ?? Icons.label_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}





class _FullScreenshotView extends StatelessWidget {
  const _FullScreenshotView({
    required this.screenshotUrl,
    required this.testerUid,
    required this.testerName,
    required this.submittedAt,
    required this.appDetails,
    this.issueType,
    this.reportText,
  });

  final String screenshotUrl;
  final String testerUid;
  final String testerName;
  final DateTime submittedAt;
  final AppDetails appDetails;
  final String? issueType;
  final String? reportText;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              appDetails.appName,
              style: tt.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '@$testerName · '
              '${DateFormat('dd MMM yyyy, hh:mm a').format(submittedAt)}',
              style: tt.labelSmall?.copyWith(color: Colors.white54),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Hero(
              tag: 'sheet_screenshot_${testerUid}_$submittedAt',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 5.0,
                child: Center(
                  child: Image.network(
                    screenshotUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_rounded,
                      size: 64,
                      color: Colors.white38,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}





class _IconFallback extends StatelessWidget {
  const _IconFallback({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    color: _deepBlue.withOpacity(0.08),
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : 'A',
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: _deepBlue,
      ),
    ),
  );
}
