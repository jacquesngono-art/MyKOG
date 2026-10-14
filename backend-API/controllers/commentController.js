const { db } = require('../config/firebase');

const COMMENTS_LIMIT = 500;

function formatComment(doc) {
  const data = doc.data();
  return {
    id: doc.id,
    author: data.author || 'Anonyme',
    userId: data.userId || null,
    content: data.content || '',
    avatar: data.avatar || '',
    parentId: data.parentId || null,
    votes: data.votes || 0,
    createdAt: data.createdAt?.toDate ? data.createdAt.toDate() : null,
    updatedAt: data.updatedAt?.toDate ? data.updatedAt.toDate() : null,
  };
}

// Photos de profil actuelles pour un ensemble de userIds
async function getUserAvatars(userIds) {
  const map = new Map();
  if (!userIds.length) return map;
  const docs = await Promise.all(
    userIds.map(uid => db.collection('users').doc(uid).get().catch(() => null))
  );
  docs.forEach(doc => {
    if (doc && doc.exists) {
      const url = doc.data().profileImageUrl;
      if (url) map.set(doc.id, url);
    }
  });
  return map;
}

// Construit l'arbre de commentaires à partir de la liste plate
function buildCommentTree(flatComments) {
  const byId = new Map();
  const roots = [];
  flatComments.forEach(c => byId.set(c.id, { ...c, replies: [] }));
  flatComments.forEach(c => {
    const node = byId.get(c.id);
    if (c.parentId && byId.has(c.parentId)) {
      byId.get(c.parentId).replies.push(node);
    } else {
      roots.push(node);
    }
  });
  const sortByDate = arr => {
    arr.sort((a, b) => (b.createdAt?.getTime() || 0) - (a.createdAt?.getTime() || 0));
    arr.forEach(c => {
      // Les réponses en ordre chronologique (les plus anciennes d'abord)
      c.replies.sort((a, b) => (a.createdAt?.getTime() || 0) - (b.createdAt?.getTime() || 0));
    });
  };
  sortByDate(roots);
  return roots;
}

// Récupérer tous les commentaires d'un live (arbre imbriqué)
const getComments = async (req, res) => {
  try {
    const { id } = req.params;
    const liveDoc = await db.collection('liveStreams').doc(id).get();
    if (!liveDoc.exists) {
      return res.status(404).json({ error: 'Live stream non trouvé' });
    }

    const snapshot = await db
      .collection('liveStreams')
      .doc(id)
      .collection('comments')
      .orderBy('createdAt', 'desc')
      .limit(COMMENTS_LIMIT)
      .get();

    const flat = snapshot.docs.map(formatComment);
    // Enrichir avec la photo de profil actuelle de l'utilisateur
    // (couvre les anciens commentaires sans avatar et les URL expirées)
    const avatars = await getUserAvatars([...new Set(flat.map(c => c.userId).filter(Boolean))]);
    flat.forEach(c => {
      const url = avatars.get(c.userId);
      if (url) c.avatar = url;
    });
    res.json({ comments: buildCommentTree(flat), count: flat.length });
  } catch (error) {
    console.error('Erreur récupération commentaires:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des commentaires' });
  }
};

// Poster un commentaire (ou une réponse si parentId fourni)
const createComment = async (req, res) => {
  try {
    const { id } = req.params;
    const { content, author, userId, avatar, parentId } = req.body || {};

    if (!content || !content.trim()) {
      return res.status(400).json({ error: 'Le contenu du commentaire est requis' });
    }
    if (content.length > 2000) {
      return res.status(400).json({ error: 'Le commentaire ne peut pas dépasser 2000 caractères' });
    }

    const liveRef = db.collection('liveStreams').doc(id);
    const liveDoc = await liveRef.get();
    if (!liveDoc.exists) {
      return res.status(404).json({ error: 'Live stream non trouvé' });
    }

    // Vérifier que le parent existe si c'est une réponse
    if (parentId) {
      const parentDoc = await liveRef.collection('comments').doc(parentId).get();
      if (!parentDoc.exists) {
        return res.status(404).json({ error: 'Commentaire parent non trouvé' });
      }
    }

    const now = new Date();

    // Si l'avatar n'est pas fourni, récupérer la photo de profil de l'utilisateur
    let avatarUrl = avatar || '';
    if (!avatarUrl && userId) {
      const userDoc = await db.collection('users').doc(userId).get().catch(() => null);
      if (userDoc && userDoc.exists) avatarUrl = userDoc.data().profileImageUrl || '';
    }

    const commentData = {
      author: (author || 'Anonyme').toString().slice(0, 80),
      userId: userId || null,
      content: content.trim(),
      avatar: avatarUrl,
      parentId: parentId || null,
      votes: 0,
      createdAt: now,
      updatedAt: now,
    };

    const ref = await liveRef.collection('comments').add(commentData);
    const doc = await ref.get();

    res.status(201).json({ message: 'Commentaire ajouté', comment: formatComment(doc) });
  } catch (error) {
    console.error('Erreur création commentaire:', error);
    res.status(500).json({ error: 'Erreur lors de la création du commentaire' });
  }
};

// Voter sur un commentaire (+1 / -1)
const voteComment = async (req, res) => {
  try {
    const { id, commentId } = req.params;
    const { delta } = req.body || {};

    if (![1, -1].includes(delta)) {
      return res.status(400).json({ error: 'delta doit être 1 ou -1' });
    }

    const ref = db.collection('liveStreams').doc(id).collection('comments').doc(commentId);
    const doc = await ref.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Commentaire non trouvé' });
    }

    const newVotes = (doc.data().votes || 0) + delta;
    await ref.update({ votes: newVotes, updatedAt: new Date() });

    res.json({ id: commentId, votes: newVotes });
  } catch (error) {
    console.error('Erreur vote commentaire:', error);
    res.status(500).json({ error: 'Erreur lors du vote' });
  }
};

// Modifier un commentaire
const updateComment = async (req, res) => {
  try {
    const { id, commentId } = req.params;
    const { content } = req.body || {};

    if (!content || !content.trim()) {
      return res.status(400).json({ error: 'Le contenu du commentaire est requis' });
    }

    const ref = db.collection('liveStreams').doc(id).collection('comments').doc(commentId);
    const doc = await ref.get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Commentaire non trouvé' });
    }

    await ref.update({ content: content.trim(), updatedAt: new Date() });
    const updated = await ref.get();

    res.json({ message: 'Commentaire mis à jour', comment: formatComment(updated) });
  } catch (error) {
    console.error('Erreur mise à jour commentaire:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour du commentaire' });
  }
};

// Supprimer un commentaire (et ses réponses)
const deleteComment = async (req, res) => {
  try {
    const { id, commentId } = req.params;
    const commentsRef = db.collection('liveStreams').doc(id).collection('comments');

    const doc = await commentsRef.doc(commentId).get();
    if (!doc.exists) {
      return res.status(404).json({ error: 'Commentaire non trouvé' });
    }

    // Supprimer récursivement les réponses
    const deleteReplies = async parentId => {
      const replies = await commentsRef.where('parentId', '==', parentId).get();
      for (const reply of replies.docs) {
        await deleteReplies(reply.id);
        await reply.ref.delete();
      }
    };
    await deleteReplies(commentId);
    await commentsRef.doc(commentId).delete();

    res.json({ id: commentId, message: 'Commentaire supprimé' });
  } catch (error) {
    console.error('Erreur suppression commentaire:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression du commentaire' });
  }
};

module.exports = {
  getComments,
  createComment,
  voteComment,
  updateComment,
  deleteComment,
};
