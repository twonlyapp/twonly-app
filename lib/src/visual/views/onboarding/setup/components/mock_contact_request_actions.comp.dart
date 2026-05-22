import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/themes/light.dart';

class MockContactRequestActionsComp extends StatelessWidget {
  const MockContactRequestActionsComp({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 20,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.only(right: 2, left: 4),
                      backgroundColor: context.color.surfaceContainerHigh,
                      foregroundColor: context.color.onSurface,
                    ),
                    onPressed: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_off_rounded,
                          color: Color.fromARGB(164, 244, 67, 54),
                          size: 12,
                        ),
                        Text(
                          context.lang.contactActionBlock,
                          style: const TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 20,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.only(right: 2, left: 4),
                      backgroundColor: context.color.surfaceContainerHigh,
                      foregroundColor: context.color.onSurface,
                    ),
                    onPressed: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, color: Colors.green, size: 12),
                        Text(
                          context.lang.contactActionAccept,
                          style: const TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            IconButton(
              style: IconButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.close, size: 12),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class MockContactSuggestedActionsComp extends StatelessWidget {
  const MockContactSuggestedActionsComp({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                height: 20,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.only(right: 8, left: 4),
                  ).merge(secondaryGreyButtonStyle(context)),
                  onPressed: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: FaIcon(FontAwesomeIcons.circleQuestion, size: 10),
                      ),
                      Text(
                        context.lang.friendSuggestionsAskFriend,
                        style: const TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 20,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.only(right: 8, left: 4),
                  ).merge(secondaryGreyButtonStyle(context)),
                  onPressed: () {},
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: FaIcon(FontAwesomeIcons.userPlus, size: 10),
                      ),
                      Text(
                        context.lang.friendSuggestionsRequest,
                        style: const TextStyle(fontSize: 8),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            style: IconButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close, size: 12),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
