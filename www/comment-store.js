/**
 * CommentStore — Robust, editor-agnostic comment management.
 *
 * Stores comments using absolute character offsets (from, to) instead of
 * row/column pairs. This makes range tracking immune to the position-loss
 * bugs that plague the old Ace Anchor approach.
 *
 * Both Ace and CM6 editors interact through the same API.
 * Change mapping is the critical improvement: when either editor fires a
 * document change, all comment offsets are mapped through the change.
 */
(function () {
  'use strict';

  var MAX_NESTING_DEPTH = 3;

  /**
   * @constructor
   */
  function CommentStore() {
    /** @type {Map<string, Object>} */
    this.comments = new Map();
    this._listeners = [];
    this._frozen = false; // CRITICAL: freeze mapping during bulk operations
  }

  // ─── Event System ────────────────────────────────────────────

  CommentStore.prototype.on = function (fn) {
    this._listeners.push(fn);
  };

  CommentStore.prototype.off = function (fn) {
    this._listeners = this._listeners.filter(function (f) { return f !== fn; });
  };

  CommentStore.prototype._emit = function () {
    for (var i = 0; i < this._listeners.length; i++) {
      try { this._listeners[i](); } catch (e) { console.error('[CommentStore] listener error:', e); }
    }
  };

  /**
   * Freeze offset mapping — prevents mapAceDelta/mapCM6Changes from
   * corrupting offsets during bulk operations like setValue() on mode switch.
   */
  CommentStore.prototype.freeze = function () {
    this._frozen = true;
  };

  CommentStore.prototype.unfreeze = function () {
    this._frozen = false;
  };

  // ─── Load / Export ───────────────────────────────────────────

  /**
   * Load comments from an array (as received from R server).
   * Each comment must have { id, from, to, ... }.
   */
  CommentStore.prototype.loadFromServer = function (commentsArray) {
    this.comments.clear();
    if (!commentsArray || !Array.isArray(commentsArray)) {
      this._emit();
      return;
    }
    for (var i = 0; i < commentsArray.length; i++) {
      var c = commentsArray[i];
      if (c && c.id) {
        // Ensure integer offsets
        c.from = parseInt(c.from, 10) || 0;
        c.to = parseInt(c.to, 10) || 0;
        this.comments.set(c.id, c);
      }
    }
    this._emit();
  };

  /**
   * Export all comments as an array for saving to R server.
   */
  CommentStore.prototype.toJSON = function () {
    var result = [];
    this.comments.forEach(function (c) {
      result.push(c);
    });
    return result;
  };

  // ─── Change Mapping ──────────────────────────────────────────

  /**
   * Map all comment offsets through an Ace-style change delta.
   * Called from Ace's 'change' event listener.
   *
   * CRITICAL: Ace's change event fires AFTER the document is modified.
   * For 'insert': delta.start is where text was inserted (valid in both old & new doc)
   * For 'remove': delta.start is where deletion begins (valid in both old & new doc),
   *               delta.lines contains the removed text for length calculation.
   *
   * Since our stored offsets are in the OLD coordinate space, we map them
   * to the NEW coordinate space by shifting them based on the change.
   *
   * @param {Object} delta - Ace delta
   * @param {Object} aceDoc - Ace's document (already modified)
   */
  CommentStore.prototype.mapAceDelta = function (delta, aceDoc) {
    if (!delta || !aceDoc) return;
    if (this._frozen) return; // Skip during mode switches

    // Calculate the absolute offset of the change start using the lines
    // BEFORE the change point (which are the same in old and new doc).
    // We can safely use positionToIndex for delta.start because that position
    // exists in both old and new documents.
    var changeFrom = aceDoc.positionToIndex(delta.start, 0);
    var insertLen, deleteLen;

    if (delta.action === 'insert') {
      var insertedText = delta.lines.join('\n');
      insertLen = insertedText.length;
      deleteLen = 0;
    } else if (delta.action === 'remove') {
      var removedText = delta.lines.join('\n');
      insertLen = 0;
      deleteLen = removedText.length;
    } else {
      return;
    }

    // Skip trivial changes
    if (insertLen === 0 && deleteLen === 0) return;

    this._mapOffsets(changeFrom, deleteLen, insertLen);
  };

  /**
   * Map all comment offsets through a CM6 ChangeSet.
   * Called after CM6 transactions.
   *
   * @param {Object} changes - CM6 ChangeSet object
   */
  CommentStore.prototype.mapCM6Changes = function (changes) {
    if (!changes) return;
    if (this._frozen) return;

    var changed = false;
    this.comments.forEach(function (c) {
      var newFrom = changes.mapPos(c.from, 1);
      var newTo = changes.mapPos(c.to, -1);
      if (newTo < newFrom) newTo = newFrom;

      if (newFrom !== c.from || newTo !== c.to) {
        c.from = newFrom;
        c.to = newTo;
        changed = true;
      }
    });

    if (changed) {
      this._emit();
    }
  };

  /**
   * Core offset mapping logic for Ace-style changes.
   * Maps all stored offsets from OLD doc coordinates to NEW doc coordinates.
   *
   * Given a change at position `changeAt`:
   *   - deleteLen characters were removed starting at changeAt (in OLD doc)
   *   - insertLen characters were inserted at changeAt (in NEW doc)
   *
   * OLD doc: [...before...][...deleted_text...][...after...]
   *                        ^changeAt           ^changeAt+deleteLen
   *
   * NEW doc: [...before...][...inserted_text...][...after...]
   *                        ^changeAt            ^changeAt+insertLen
   */
  CommentStore.prototype._mapOffsets = function (changeAt, deleteLen, insertLen) {
    var changeEnd = changeAt + deleteLen; // End of deleted region in OLD doc
    var netShift = insertLen - deleteLen;
    var changed = false;

    this.comments.forEach(function (c) {
      var newFrom = c.from;
      var newTo = c.to;

      // Map 'from': if it's after the deleted region, shift it.
      // If it's inside the deleted region, collapse to changeAt + insertLen.
      if (c.from >= changeEnd) {
        newFrom = c.from + netShift;
      } else if (c.from > changeAt) {
        newFrom = changeAt + insertLen;
      }

      // Map 'to' similarly
      // CONSISTENCY FIX: Use > instead of >= for 'to' to match CM6 mapPos(pos, -1)
      // This prevents the highlight from expanding when typing at the very end of it.
      if (c.to > changeEnd) {
        newTo = c.to + netShift;
      } else if (c.to > changeAt) {
        newTo = changeAt + insertLen;
      }

      // Clamp
      if (newTo < newFrom) newTo = newFrom;
      if (newFrom < 0) newFrom = 0;
      if (newTo < 0) newTo = 0;

      if (newFrom !== c.from || newTo !== c.to) {
        c.from = newFrom;
        c.to = newTo;
        changed = true;
      }
    });

    if (changed) {
      this._emit();
    }
  };

  // ─── CRUD ────────────────────────────────────────────────────

  CommentStore.prototype.addComment = function (commentData) {
    if (!commentData || !commentData.id) return;
    commentData.from = parseInt(commentData.from, 10) || 0;
    commentData.to = parseInt(commentData.to, 10) || 0;
    if (!commentData.replies) commentData.replies = [];
    if (commentData.resolved === undefined) commentData.resolved = false;
    this.comments.set(commentData.id, commentData);
    this._emit();
    return commentData;
  };

  CommentStore.prototype.getComment = function (id) {
    return this.comments.get(id) || null;
  };

  CommentStore.prototype.deleteComment = function (id) {
    var existed = this.comments.delete(id);
    if (existed) this._emit();
    return existed;
  };

  CommentStore.prototype.resolveComment = function (id) {
    var c = this.comments.get(id);
    if (c) {
      c.resolved = !c.resolved;
      this._emit();
    }
  };

  CommentStore.prototype.updateContent = function (id, content) {
    var c = this.comments.get(id);
    if (c) {
      c.content = content;
      c.isEditing = false;
      this._emit();
    }
  };

  CommentStore.prototype.setEditing = function (id, isEditing) {
    var c = this.comments.get(id);
    if (c) {
      c.isEditing = !!isEditing;
      this._emit();
    }
  };

  // ─── Reply Operations (Recursive, Max Depth 3) ──────────────

  CommentStore.prototype._getDepth = function (parentId) {
    if (this.comments.has(parentId)) return 0;
    var depth = -1;
    this.comments.forEach(function (c) {
      if (depth >= 0) return;
      var d = _findDepthInReplies(c.replies, parentId, 1);
      if (d >= 0) depth = d;
    });
    return depth;
  };

  function _findDepthInReplies(replies, targetId, currentDepth) {
    if (!replies) return -1;
    for (var i = 0; i < replies.length; i++) {
      if (replies[i].id === targetId) return currentDepth;
      var d = _findDepthInReplies(replies[i].replies, targetId, currentDepth + 1);
      if (d >= 0) return d;
    }
    return -1;
  }

  CommentStore.prototype.addReply = function (parentId, replyData) {
    var parentDepth = this._getDepth(parentId);
    if (parentDepth < 0) return false;
    if (parentDepth + 1 >= MAX_NESTING_DEPTH) return false;

    if (!replyData.replies) replyData.replies = [];
    replyData.isEditing = false;

    var c = this.comments.get(parentId);
    if (c) {
      if (!c.replies) c.replies = [];
      c.replies.push(replyData);
      this._emit();
      return true;
    }

    var found = false;
    this.comments.forEach(function (comment) {
      if (!found) {
        found = _addReplyRecursive(comment.replies, parentId, replyData);
      }
    });
    if (found) this._emit();
    return found;
  };

  function _addReplyRecursive(replies, parentId, replyData) {
    if (!replies) return false;
    for (var i = 0; i < replies.length; i++) {
      if (replies[i].id === parentId) {
        if (!replies[i].replies) replies[i].replies = [];
        replies[i].replies.push(replyData);
        return true;
      }
      if (_addReplyRecursive(replies[i].replies, parentId, replyData)) return true;
    }
    return false;
  }

  CommentStore.prototype.deleteReply = function (commentId, replyId) {
    var c = this.comments.get(commentId);
    if (!c) return false;
    c.replies = _deleteReplyRecursive(c.replies || [], replyId);
    this._emit();
    return true;
  };

  function _deleteReplyRecursive(replies, targetId) {
    replies = replies.filter(function (r) { return r.id !== targetId; });
    for (var i = 0; i < replies.length; i++) {
      if (replies[i].replies && replies[i].replies.length > 0) {
        replies[i].replies = _deleteReplyRecursive(replies[i].replies, targetId);
      }
    }
    return replies;
  }

  CommentStore.prototype.editReply = function (commentId, replyId, content) {
    var c = this.comments.get(commentId);
    if (!c) return false;
    var found = _editReplyRecursive(c.replies || [], replyId, content);
    if (found) this._emit();
    return found;
  };

  function _editReplyRecursive(replies, targetId, content) {
    for (var i = 0; i < replies.length; i++) {
      if (replies[i].id === targetId) {
        replies[i].content = content;
        replies[i].isEditing = false;
        return true;
      }
      if (_editReplyRecursive(replies[i].replies || [], targetId, content)) return true;
    }
    return false;
  }

  CommentStore.prototype.setReplyEditing = function (commentId, replyId, isEditing) {
    var c = this.comments.get(commentId);
    if (!c) return;
    _setReplyEditingRecursive(c.replies || [], replyId, isEditing);
    this._emit();
  };

  function _setReplyEditingRecursive(replies, targetId, isEditing) {
    for (var i = 0; i < replies.length; i++) {
      if (replies[i].id === targetId) {
        replies[i].isEditing = !!isEditing;
        return true;
      }
      if (_setReplyEditingRecursive(replies[i].replies || [], targetId, isEditing)) return true;
    }
    return false;
  }

  // ─── Query Helpers ───────────────────────────────────────────

  CommentStore.prototype.getActiveComments = function () {
    var result = [];
    this.comments.forEach(function (c) {
      if (!c.resolved) result.push(c);
    });
    result.sort(function (a, b) { return a.from - b.from; });
    return result;
  };

  CommentStore.prototype.getResolvedComments = function () {
    var result = [];
    this.comments.forEach(function (c) {
      if (c.resolved) result.push(c);
    });
    result.sort(function (a, b) { return a.from - b.from; });
    return result;
  };

  CommentStore.prototype.getAllComments = function () {
    var result = [];
    this.comments.forEach(function (c) { result.push(c); });
    result.sort(function (a, b) { return a.from - b.from; });
    return result;
  };

  CommentStore.prototype.getCommentAtOffset = function (offset) {
    var best = null;
    var bestLen = Infinity;
    this.comments.forEach(function (c) {
      if (c.resolved) return;
      if (offset >= c.from && offset <= c.to) {
        var len = c.to - c.from;
        if (len < bestLen) {
          bestLen = len;
          best = c;
        }
      }
    });
    return best;
  };

  // ─── Static Helpers ──────────────────────────────────────────

  CommentStore.rowColToOffset = function (aceDoc, row, col) {
    if (!aceDoc || typeof aceDoc.positionToIndex !== 'function') {
      var lines = aceDoc ? aceDoc.getAllLines() : [];
      var offset = 0;
      for (var i = 0; i < row && i < lines.length; i++) {
        offset += lines[i].length + 1;
      }
      return offset + col;
    }
    return aceDoc.positionToIndex({ row: row, column: col }, 0);
  };

  CommentStore.offsetToRowCol = function (aceDoc, offset) {
    if (!aceDoc || typeof aceDoc.indexToPosition !== 'function') {
      var lines = aceDoc ? aceDoc.getAllLines() : [];
      var remaining = offset;
      for (var i = 0; i < lines.length; i++) {
        if (remaining <= lines[i].length) {
          return { row: i, column: remaining };
        }
        remaining -= lines[i].length + 1;
      }
      return { row: Math.max(0, lines.length - 1), column: 0 };
    }
    return aceDoc.indexToPosition(offset, 0);
  };

  // ─── Expose Globally ─────────────────────────────────────────

  window.CommentStore = CommentStore;
  window.commentStore = new CommentStore();
})();
