import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:MyKOG/models/live_comment.dart';
import 'package:MyKOG/api/live_api_service.dart';
import 'package:MyKOG/providers/user_provider.dart';
import 'package:MyKOG/theme.dart';

/// Panneau de commentaires d'un live — style fil Reddit
/// (avatar, auteur • temps, votes, réponses imbriquées, réduire/déplier)
class LiveCommentsPanel extends StatefulWidget {
  final String liveId;

  const LiveCommentsPanel({super.key, required this.liveId});

  @override
  State<LiveCommentsPanel> createState() => _LiveCommentsPanelState();
}

class _LiveCommentsPanelState extends State<LiveCommentsPanel> {
  final LiveApiService _api = LiveApiService();
  final TextEditingController _inputCtrl = TextEditingController();

  List<LiveComment> _comments = [];
  Timer? _pollTimer;
  String? _replyingTo;
  String? _editingId;
  String? _lastJson;
  final Set<String> _collapsed = {};

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _api.getComments(widget.liveId);
    if (!mounted) return;
    final json = list.map((c) => '${c.id}${c.content}${c.votes}${_countAll(c.replies)}').join();
    if (json == _lastJson) return;
    _lastJson = json;
    setState(() => _comments = list);
  }

  int _countAll(List<LiveComment> list) =>
      list.fold(0, (n, c) => n + 1 + _countAll(c.replies));

  String _timeAgo(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    final mins = diff.inMinutes;
    if (mins < 1) return "À l'instant";
    if (mins < 60) return 'il y a $mins min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return 'il y a ${diff.inDays} j';
  }

  LiveComment? _find(String id, [List<LiveComment>? list]) {
    for (final c in list ?? _comments) {
      if (c.id == id) return c;
      final f = _find(id, c.replies);
      if (f != null) return f;
    }
    return null;
  }

  Future<void> _submit(String content, {String? parentId}) async {
    if (content.trim().isEmpty) return;
    final user = context.read<UserProvider>().currentUser;
    try {
      final comment = await _api.postComment(
        widget.liveId,
        content: content.trim(),
        author: user?.name ?? 'Anonyme',
        userId: user?.id,
        avatar: user?.profileImageUrl,
        parentId: parentId,
      );
      if (comment == null || !mounted) return;
      setState(() {
        if (parentId == null) {
          _comments.insert(0, comment);
        } else {
          _find(parentId)?.replies.add(comment);
          _replyingTo = null;
        }
        _lastJson = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _vote(LiveComment c, int delta) async {
    setState(() => c.votes += delta);
    await _api.voteComment(widget.liveId, c.id, delta);
  }

  Future<void> _delete(LiveComment c) async {
    final ok = await _api.deleteComment(widget.liveId, c.id);
    if (ok && mounted) {
      setState(() {
        _removeFromTree(c.id, _comments);
        _lastJson = null;
      });
    }
  }

  bool _removeFromTree(String id, List<LiveComment> list) {
    final i = list.indexWhere((c) => c.id == id);
    if (i != -1) {
      list.removeAt(i);
      return true;
    }
    return list.any((c) => _removeFromTree(id, c.replies));
  }

  @override
  Widget build(BuildContext context) {
    final total = _countAll(_comments);
    return Container(
      color: const Color(0xFF0E0E0E),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline,
                    color: MyKOGColors.accent, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Commentaires',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$total',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Input principal
          _CommentInput(
            controller: _inputCtrl,
            authorName:
                context.watch<UserProvider>().currentUser?.name ?? 'Anonyme',
            avatarUrl:
                context.watch<UserProvider>().currentUser?.profileImageUrl,
            hint: 'Rejoignez la conversation…',
            onSubmit: (text) {
              _submit(text);
              _inputCtrl.clear();
            },
          ),

          const SizedBox(height: 10),

          // Fil de commentaires
          Expanded(
            child: _comments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline,
                            color: Colors.white.withOpacity(0.25), size: 44),
                        const SizedBox(height: 10),
                        const Text(
                          'Aucun commentaire.\nSoyez le premier à réagir !',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: _comments.length,
                    itemBuilder: (_, i) => _buildComment(_comments[i], 0),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildComment(LiveComment c, int level) {
    final isCollapsed = _collapsed.contains(c.id);
    final hasReplies = c.replies.isNotEmpty;
    final isReplying = _replyingTo == c.id;
    final isEditing = _editingId == c.id;
    final user = context.watch<UserProvider>().currentUser;
    final isMine = user != null && c.userId == user.id;

    return Container(
      margin: EdgeInsets.only(left: level > 0 ? 30 : 0, bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ligne verticale de connexion pour les réponses
            if (level > 0)
              Container(
                width: 1,
                margin: const EdgeInsets.only(right: 10),
                color: Colors.white.withOpacity(0.12),
              ),

            // Avatar
            GestureDetector(
              onTap: isCollapsed
                  ? () => setState(() => _collapsed.remove(c.id))
                  : null,
              child: _Avatar(
                  name: c.author,
                  size: 36,
                  imageUrl: c.avatar.isNotEmpty ? c.avatar : null,
                  collapsed: isCollapsed),
            ),
            const SizedBox(width: 10),

            // Corps
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header : auteur • temps
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          c.author,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(' • ',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 12)),
                      Text(
                        _timeAgo(c.createdAt),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),

                  if (isEditing)
                    _EditBox(
                      initial: c.content,
                      onSave: (text) async {
                        final updated = await _api.updateComment(
                            widget.liveId, c.id, text);
                        if (updated != null && mounted) {
                          setState(() {
                            _editingId = null;
                            _lastJson = null;
                            _load();
                          });
                        }
                      },
                      onCancel: () => setState(() => _editingId = null),
                    )
                  else if (!isCollapsed)
                    Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                      child: Text(
                        c.content,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 14, height: 1.4),
                      ),
                    ),

                  if (isCollapsed && hasReplies)
                    Text(
                      '${c.replies.length} réponse(s)',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                    ),

                  // Actions
                  if (!isCollapsed)
                    Row(
                      children: [
                        if (hasReplies)
                          _ActionBtn(
                            icon: Icons.remove_circle_outline,
                            onTap: () =>
                                setState(() => _collapsed.add(c.id)),
                          ),
                        _VoteBtn(
                          icon: Icons.arrow_upward,
                          onTap: () => _vote(c, 1),
                        ),
                        SizedBox(
                          width: 18,
                          child: Text(
                            '${c.votes}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        _VoteBtn(
                          icon: Icons.arrow_downward,
                          onTap: () => _vote(c, -1),
                        ),
                        _ActionBtn(
                          icon: Icons.chat_bubble_outline,
                          label: 'Répondre',
                          onTap: () => setState(() {
                            _replyingTo = isReplying ? null : c.id;
                            _editingId = null;
                          }),
                        ),
                        if (isMine) ...[
                          _ActionBtn(
                            icon: Icons.edit_outlined,
                            onTap: () => setState(() {
                              _editingId = c.id;
                              _replyingTo = null;
                            }),
                          ),
                          _ActionBtn(
                            icon: Icons.delete_outline,
                            color: Colors.redAccent,
                            onTap: () => _delete(c),
                          ),
                        ],
                      ],
                    ),

                  // Input de réponse
                  if (isReplying && !isCollapsed)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _CommentInput(
                        authorName: user?.name ?? 'Anonyme',
                        avatarUrl: user?.profileImageUrl,
                        hint: 'Écrivez une réponse…',
                        autofocus: true,
                        onSubmit: (text) => _submit(text, parentId: c.id),
                        onCancel: () =>
                            setState(() => _replyingTo = null),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Champ de saisie arrondi : avatar + textarea + bouton envoi doré
class _CommentInput extends StatefulWidget {
  final TextEditingController? controller;
  final String authorName;
  final String? avatarUrl;
  final String hint;
  final bool autofocus;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onCancel;

  const _CommentInput({
    this.controller,
    required this.authorName,
    this.avatarUrl,
    required this.hint,
    this.autofocus = false,
    required this.onSubmit,
    this.onCancel,
  });

  @override
  State<_CommentInput> createState() => _CommentInputState();
}

class _CommentInputState extends State<_CommentInput> {
  late final TextEditingController _ctrl =
      widget.controller ?? TextEditingController();

  @override
  void dispose() {
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    if (widget.controller == null) _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Avatar(name: widget.authorName, size: 30, imageUrl: widget.avatarUrl),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _ctrl,
              autofocus: widget.autofocus,
              maxLines: null,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle:
                    const TextStyle(color: Colors.white38, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          if (widget.onCancel != null)
            TextButton(
              onPressed: widget.onCancel,
              style: TextButton.styleFrom(
                  foregroundColor: Colors.white38,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4)),
              child: const Text('Annuler', style: TextStyle(fontSize: 12)),
            ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: MyKOGColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward,
                  color: Colors.black, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar circulaire : photo de profil si dispo, sinon première lettre (dégradé doré)
class _Avatar extends StatelessWidget {
  final String name;
  final double size;
  final String? imageUrl;
  final bool collapsed;

  const _Avatar({
    required this.name,
    this.size = 36,
    this.imageUrl,
    this.collapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add_circle_outline,
            color: Colors.white54, size: size * 0.5),
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _letterAvatar(),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _letterAvatar(),
        ),
      );
    }
    return _letterAvatar();
  }

  Widget _letterAvatar() {
    final letter =
        name.trim().isEmpty ? 'A' : name.trim()[0].toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [MyKOGColors.accent, Color(0xFF8A6D1F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color ?? Colors.white54),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(label!,
                  style: TextStyle(
                      fontSize: 12, color: color ?? Colors.white54)),
            ],
          ],
        ),
      ),
    );
  }
}

class _VoteBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _VoteBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Icon(icon, size: 15, color: Colors.white54),
      ),
    );
  }
}

class _EditBox extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  const _EditBox({
    required this.initial,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_EditBox> createState() => _EditBoxState();
}

class _EditBoxState extends State<_EditBox> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          maxLines: null,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.all(10),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => widget.onSave(_ctrl.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyKOGColors.accent,
                foregroundColor: Colors.black,
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: const Text('Enregistrer'),
            ),
            TextButton(
              onPressed: widget.onCancel,
              style:
                  TextButton.styleFrom(foregroundColor: Colors.white54),
              child: const Text('Annuler',
                  style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }
}
