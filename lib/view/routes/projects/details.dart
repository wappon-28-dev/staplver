import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../model/constant.dart';
import '../../../model/error/handler.dart';
import '../../../repository/svn.dart';
import '../../../vm/page.dart';
import '../../../vm/projects.dart';
import '../../components/navbar.dart';
import '../../components/projects/history.dart';

class CompProjectsDetails extends HookConsumerWidget {
  const CompProjectsDetails({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // state
    final projectsState = ref.watch(projectsProvider);
    final pj = projectsState.currentPj;

    // assert
    if (pj == null) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Text('No project selected'),
        ),
      );
    }

    // notifier
    final pageNotifier = ref.read(pageProvider.notifier);
    final orientation = MediaQuery.of(context).orientation;

    // local
    final isLaunching = useState(false);
    final pjInfo = useMemoized(
      () async => SvnRepository().getRepositoryInfo(pj.workingDir),
    );
    final pjHistory = useMemoized(
      () async => SvnRepository().getRevisionsLog(pj.workingDir),
    );

    final pjInfoSnapshot = useFuture(pjInfo);
    final pjHistorySnapshot = useFuture(pjHistory);

    // init
    void init() {
      ref.read(pageProvider.notifier)
        ..updateIsVisibleProgressBar(true)
        ..updateProgress(-1);
    }

    useEffect(() => onMounted(init), []);

    useEffect(
      () => onMountedAsync(() async {
        if (pjInfoSnapshot.hasData && pjHistorySnapshot.hasData) {
          await pageNotifier.completeProgress();
        } else if (pjInfoSnapshot.hasError || pjHistorySnapshot.hasError) {
          AIBASErrHandler(context, ref).noticeErr(
            pjInfoSnapshot.error,
            pjInfoSnapshot.stackTrace ?? StackTrace.empty,
          );
          await pageNotifier.completeProgress();
        }
      }),
      [pjInfoSnapshot, pjHistorySnapshot],
    );

    // view
    final actionChips = [
      SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('監視ストップ'),
                avatar: const Icon(Icons.stop_circle_outlined),
                onPressed: () {},
              ),
              ActionChip(
                label: const Text('最新の情報へ更新'),
                avatar: const Icon(Icons.refresh),
                onPressed: () {},
              ),
              ActionChip(
                label: const Text('作業フォルダーを開く'),
                avatar: isLaunching.value
                    ? const Padding(
                        padding: EdgeInsets.all(2),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.folder_open),
                iconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                onPressed: !isLaunching.value
                    ? () async {
                        isLaunching.value = true;
                        await launchUrl(pj.workingDir.uri);
                        isLaunching.value = false;
                      }
                    : null,
              ),
              ActionChip(
                label: const Text('プロジェクトの設定'),
                avatar: const Icon(Icons.settings),
                iconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      const Divider(),
      SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              ActionChip(
                label: Text('カスタム'),
                avatar: Icon(Icons.emoji_nature),
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
      const Divider(),
    ];

    final info = [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                child: Text(
                  pjInfoSnapshot.data?.toJson().toString() ?? '',
                ),
              ),
            ),
            const SizedBox(child: VerticalDivider()),
            const Expanded(child: CompPjHistory())
          ],
        ),
      )
    ];

    Widget content() {
      if (pjInfoSnapshot.hasData &&
          pjInfoSnapshot.data != null &&
          pjHistorySnapshot.hasData &&
          pjHistorySnapshot.data != null) {
        return Column(
          children: [
            const SizedBox(height: 10),
            ...actionChips,
            ...info,
          ],
        );
      } else if (pjInfoSnapshot.hasError || pjHistorySnapshot.hasError) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Text('SVNへの問い合わせ中にエラーが発生しました'),
          ),
        );
      } else {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(10),
            child: Text('SVNからの応答を待っています...'),
          ),
        );
      }
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        tooltip: 'セーブポイントを作成',
        child: const Icon(Icons.save),
      ),
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar.large(
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.ideographic,
              children: [
                Text(
                  pj.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 40,
                  ),
                ),
              ],
            ),
            leading: const SizedBox(),
            leadingWidth: 0,
            bottom: NavBar(ref: ref, orientation: orientation)
                .getProgressIndicator(),
            actions: [
              SizedBox(
                width: 60,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(child: content()),
        ],
      ),
    );
  }
}