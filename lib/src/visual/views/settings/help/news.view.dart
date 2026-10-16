import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/cached_network_image.dart';
import 'package:twonly/src/visual/elements/reactive_tap_feedback.element.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsView extends StatefulWidget {
  const NewsView({super.key});

  @override
  State<NewsView> createState() => _NewsViewState();
}

class _NewsViewState extends State<NewsView> {
  @override
  void initState() {
    super.initState();
    // Mark all as read when entering the page
    newsService.markAllAsRead();
    _reloadNews();
  }

  Future<void> _reloadNews() async {
    await newsService.fetchFeed();
    await newsService.markAllAsRead();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = newsService.entries;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsHelpNews),
      ),
      body: RefreshIndicator(
        onRefresh: _reloadNews,
        child: entries.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  alignment: Alignment.center,
                  child: Text(
                    'No news articles found.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: context.color.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return ReactiveTapFeedback(
                    onTap: () => launchUrl(
                      Uri.parse(entry.link),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Card(
                      color: context.color.surfaceContainerHigh,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (entry.imageUrl.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: entry.imageUrl,
                              height: 180,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 180,
                                color: context.color.surfaceContainerHighest,
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 180,
                                color: context.color.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: context.color.onSurfaceVariant,
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (entry.pubDate != null) ...[
                                  Text(
                                    DateFormat.yMMMMd(
                                      Localizations.localeOf(
                                        context,
                                      ).toString(),
                                    ).format(entry.pubDate!),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: context.color.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Text(
                                  entry.title,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  entry.description,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: context.color.onSurface
                                            .withValues(
                                              alpha: 0.8,
                                            ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
