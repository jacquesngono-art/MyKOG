"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Textarea } from "@/components/ui/textarea"
import { Card } from "@/components/ui/card"
import { MessageSquare, Edit, Check, X, MessageCircle, Award, Share, MoreHorizontal } from "lucide-react"
import { CommentInput } from "@/components/comment-input"

interface Comment {
  id: string
  content: string
  author: string
  replies: Comment[]
  createdAt: Date | null
  votes: number
  avatar: string
}

interface CommentItemProps {
  comment: Comment
  onEdit: (id: string, content: string) => void
  onReply: (parentId: string, content: string) => void
  level: number
  isLast: boolean
  hasNextSibling: boolean
  parentConnectorHovered?: boolean
  getTimeDisplay: (comment: Comment) => string
  userAvatar: string
}

const USER_AVATAR = "https://plus.unsplash.com/premium_photo-1671656349322-41de944d259b?w=40&h=40&fit=crop&crop=face"

const getTimeDisplay = (comment: Comment) => {
  if (comment.createdAt) {
    return "Just now"
  }

  const timeMap: { [key: string]: string } = {
    "1": "4h ago",
    "2": "3h ago",
    "3": "2h ago",
    "5": "2h ago",
    "6": "1h ago",
    "7": "45m ago",
  }

  return timeMap[comment.id] || "1h ago"
}

const UpvoteIcon = () => (
  <svg fill="currentColor" height="16" width="16" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
    <path d="M10 19c-.072 0-.145 0-.218-.006A4.1 4.1 0 0 1 6 14.816V11H2.862a1.751 1.751 0 0 1-1.234-2.993L9.41.28a.836.836 0 0 1 1.18 0l7.782 7.727A1.751 1.751 0 0 1 17.139 11H14v3.882a4.134 4.134 0 0 1-.854 2.592A3.99 3.99 0 0 1 10 19Zm0-17.193L2.685 9.071a.251.251 0 0 0 .177.429H7.5v5.316A2.63 2.63 0 0 0 9.864 17.5a2.441 2.441 0 0 0 1.856-.682A2.478 2.478 0 0 0 12.5 15V9.5h4.639a.25.25 0 0 0 .176-.429L10 1.807Z"></path>
  </svg>
)

const DownvoteIcon = () => (
  <svg fill="currentColor" height="16" width="16" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
    <path d="M10 1c.072 0 .145 0 .218.006A4.1 4.1 0 0 1 14 5.184V9h3.138a1.751 1.751 0 0 1 1.234 2.993L10.59 19.72a.836.836 0 0 1-1.18 0l-7.782-7.727A1.751 1.751 0 0 1 2.861 9H6V5.118a4.134 4.134 0 0 1-.854-2.592A3.99 3.99 0 0 1 10 1Zm0 17.193 7.315-7.264a.251.251 0 0 0-.177-.429H12.5V5.184A2.631 2.631 0 0 0 10.136 2.5a2.441 2.441 0 0 0-1.856.682A2.478 2.478 0 0 0 7.5 5v5.5H2.861a.251.251 0 0 0-.176.429L10 18.193Z"></path>
  </svg>
)

const CollapseIcon = () => (
  <svg fill="currentColor" height="16" width="16" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
    <path d="M14 10.625H6v-1.25h8v1.25ZM20 10a10 10 0 1 0-10 10 10.011 10.011 0 0 0 10-10Zm-1.25 0A8.75 8.75 0 1 1 10 1.25 8.76 8.76 0 0 1 18.75 10Z"></path>
  </svg>
)

const ExpandIcon = () => (
  <svg fill="currentColor" height="16" width="16" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
    <path d="M10.625 9.375H14v1.25h-3.375V14h-1.25v-3.375H6v-1.25h3.375V6h1.25v3.375ZM20 10A10 10 0 1 1 10 0a10.011 10.011 0 0 1 10 10Zm-1.25 0A8.75 8.75 0 1 0 10 18.75 8.76 8.76 0 0 0 18.75 10Z"></path>
  </svg>
)

function CommentItem({
  comment,
  onEdit,
  onReply,
  level,
  isLast,
  hasNextSibling,
  parentConnectorHovered,
  getTimeDisplay,
  userAvatar,
}: CommentItemProps) {
  const [isEditing, setIsEditing] = useState(false)
  const [editContent, setEditContent] = useState(comment.content)
  const [isReplying, setIsReplying] = useState(false)
  const [isConnectorHovered, setIsConnectorHovered] = useState(false)
  const [isCollapsed, setIsCollapsed] = useState(false)

  const handleSaveEdit = () => {
    onEdit(comment.id, editContent)
    setIsEditing(false)
  }

  const handleCancelEdit = () => {
    setEditContent(comment.content)
    setIsEditing(false)
  }

  const handleSubmitReply = (content: string) => {
    onReply(comment.id, content)
    setIsReplying(false)
  }

  const handleCancelReply = () => {
    setIsReplying(false)
  }

  return (
    <div className="relative">
      {comment.replies.length > 0 && !isCollapsed && (
        <div
          className={`absolute ${isConnectorHovered ? "bg-black" : "bg-border"}`}
          style={{
            left: "20px",
            top: "40px",
            height: "100%",
            width: "1px",
          }}
          onMouseEnter={() => setIsConnectorHovered(true)}
          onMouseLeave={() => setIsConnectorHovered(false)}
        />
      )}

      {level > 0 && (
        <div
          className={`absolute w-3 ${parentConnectorHovered ? "bg-black" : "bg-border"}`}
          style={{ left: "-12px", top: "20px", height: "1px" }}
        />
      )}

      {isLast && (
        <div className="absolute bg-background" style={{ left: "-12px", top: "21px", height: "100vh", width: "1px" }} />
      )}

      {/* Comment content */}
      <div className="mb-4">
        <div className="flex gap-3">
          {/* Avatar or Collapse Button */}
          <div className="flex-shrink-0">
            {isCollapsed ? (
              <div
                className="w-10 h-10 rounded-full bg-white flex items-center justify-center cursor-pointer"
                onClick={() => setIsCollapsed(!isCollapsed)}
              >
                <ExpandIcon />
              </div>
            ) : (
              <img
                src={comment.avatar || "/placeholder.svg?height=40&width=40"}
                alt={`${comment.author}'s avatar`}
                className="w-10 h-10 rounded-full object-cover"
              />
            )}
          </div>

          {/* Comment text or edit form */}
          <div className="flex-1 min-w-0" style={{ paddingTop: "8px" }}>
            {/* Header */}
            <div className="flex items-center gap-2 mb-2">
              <span className="text-sm font-medium text-foreground">{comment.author}</span>
              <span className="text-muted-foreground">•</span>
              <span className="text-muted-foreground text-sm">{getTimeDisplay(comment)}</span>
            </div>

            {/* Comment text or edit form */}
            {isEditing ? (
              <div className="space-y-2 mb-3">
                <Textarea
                  value={editContent}
                  onChange={(e) => setEditContent(e.target.value)}
                  className="min-h-[60px] resize-y"
                  placeholder="Edit your comment..."
                />
                <div className="flex gap-2">
                  <Button size="sm" onClick={handleSaveEdit}>
                    <Check className="w-3 h-3 mr-1" />
                    Save
                  </Button>
                  <Button size="sm" variant="outline" onClick={handleCancelEdit}>
                    <X className="w-3 h-3 mr-1" />
                    Cancel
                  </Button>
                </div>
              </div>
            ) : (
              !isCollapsed && <div className="text-foreground text-sm mb-1 whitespace-pre-wrap">{comment.content}</div>
            )}

            {/* Actions */}
            {!isCollapsed && (
              <div className="flex items-center gap-1 relative" style={{ marginLeft: "-10px" }}>
                {comment.replies.length > 0 && (
                  <div
                    className="absolute cursor-pointer z-10"
                    style={{ left: "-30px", top: "8px" }}
                    onClick={() => setIsCollapsed(!isCollapsed)}
                  >
                    <div className="bg-white rounded-full">
                      <CollapseIcon />
                    </div>
                  </div>
                )}

                {/* Vote buttons */}
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-8 px-2 text-muted-foreground hover:text-orange-600 hover:bg-orange-50 rounded-full"
                >
                  <UpvoteIcon />
                </Button>
                <span className="text-xs font-medium text-muted-foreground min-w-[1rem] text-center">
                  {comment.votes}
                </span>
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-8 px-2 text-muted-foreground hover:text-blue-600 hover:bg-blue-50 rounded-full"
                >
                  <DownvoteIcon />
                </Button>

                {/* Action buttons */}
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-8 px-3 text-xs text-muted-foreground hover:text-foreground"
                  onClick={() => setIsReplying(!isReplying)}
                >
                  <MessageCircle className="w-4 h-4 mr-1" />
                  Reply
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-8 px-3 text-xs text-muted-foreground hover:text-foreground"
                >
                  <Award className="w-4 h-4 mr-1" />
                  Award
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-8 px-3 text-xs text-muted-foreground hover:text-foreground"
                >
                  <Share className="w-4 h-4 mr-1" />
                  Share
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-8 px-2 text-xs text-muted-foreground hover:text-foreground"
                  onClick={() => setIsEditing(!isEditing)}
                >
                  <Edit className="w-4 h-4" />
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  className="h-8 px-2 text-xs text-muted-foreground hover:text-foreground"
                >
                  <MoreHorizontal className="w-4 h-4" />
                </Button>
              </div>
            )}

            {/* Reply Input */}
            {isReplying && !isCollapsed && (
              <div className="mt-4">
                <CommentInput
                  placeholder="Write a reply..."
                  onSubmit={handleSubmitReply}
                  userAvatar={userAvatar}
                  onCancel={handleCancelReply}
                />
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Nested Replies */}
      {comment.replies.length > 0 && !isCollapsed && (
        <div className="ml-8 space-y-0">
          {comment.replies.map((reply, index) => (
            <CommentItem
              key={reply.id}
              comment={reply}
              onEdit={onEdit}
              onReply={onReply}
              level={level + 1}
              isLast={index === comment.replies.length - 1}
              hasNextSibling={index < comment.replies.length - 1}
              parentConnectorHovered={isConnectorHovered}
              getTimeDisplay={getTimeDisplay}
              userAvatar={userAvatar}
            />
          ))}
        </div>
      )}
    </div>
  )
}

export default function CommentsPage() {
  const [comments, setComments] = useState<Comment[]>([
    {
      id: "1",
      content: "v0 is actually insane. Built a whole landing page in like 10 minutes lol",
      author: "dev_mike_22",
      createdAt: null,
      votes: 42,
      avatar: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=40&h=40&fit=crop&crop=face",
      replies: [
        {
          id: "2",
          content: "right?? the AI gets it. way better than copilot for UI stuff",
          author: "sarah_codes",
          createdAt: null,
          votes: 28,
          avatar: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=40&h=40&fit=crop&crop=face",
          replies: [
            {
              id: "3",
              content: "yeah the components actually look good too. not just functional",
              author: "ui_jenny",
              createdAt: null,
              votes: 15,
              avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=40&h=40&fit=crop&crop=face",
              replies: [],
            },
          ],
        },
        {
          id: "4",
          content: "wait till you try the editing feature. just tell it what to change and it does it",
          author: "react_tom",
          createdAt: null,
          votes: 31,
          avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=40&h=40&fit=crop&crop=face",
          replies: [
            {
              id: "5",
              content: "omg yes! said 'make it blue' and boom. perfect",
              author: "frontend_alex",
              createdAt: null,
              votes: 19,
              avatar: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=40&h=40&fit=crop&crop=face",
              replies: [],
            },
          ],
        },
        {
          id: "6",
          content: "They just released design systems today, no more AI look",
          author: "design_pro_88",
          createdAt: null,
          votes: 23,
          avatar: "https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=40&h=40&fit=crop&crop=face",
          replies: [],
        },
      ],
    },
  ])

  const generateId = () => Math.random().toString(36).substr(2, 9)

  const findCommentById = (comments: Comment[], id: string): Comment | null => {
    for (const comment of comments) {
      if (comment.id === id) return comment
      const found = findCommentById(comment.replies, id)
      if (found) return found
    }
    return null
  }

  const updateCommentInTree = (comments: Comment[], id: string, content: string): Comment[] => {
    return comments.map((comment) => {
      if (comment.id === id) {
        return { ...comment, content }
      }
      return {
        ...comment,
        replies: updateCommentInTree(comment.replies, id, content),
      }
    })
  }

  const addReplyToComment = (comments: Comment[], parentId: string, content: string): Comment[] => {
    return comments.map((comment) => {
      if (comment.id === parentId) {
        const newReply: Comment = {
          id: generateId(),
          content,
          author: "You",
          replies: [],
          createdAt: new Date(),
          votes: Math.floor(Math.random() * 50),
          avatar: USER_AVATAR,
        }
        return {
          ...comment,
          replies: [newReply, ...comment.replies],
        }
      }
      return {
        ...comment,
        replies: addReplyToComment(comment.replies, parentId, content),
      }
    })
  }

  const handleEditComment = (id: string, content: string) => {
    setComments((prev) => updateCommentInTree(prev, id, content))
  }

  const handleReplyToComment = (parentId: string, content: string) => {
    setComments((prev) => addReplyToComment(prev, parentId, content))
  }

  const handleAddNewComment = (content: string) => {
    const comment: Comment = {
      id: generateId(),
      content,
      author: "You",
      replies: [],
      createdAt: new Date(),
      votes: Math.floor(Math.random() * 50),
      avatar: USER_AVATAR,
    }
    setComments((prev) => [comment, ...prev])
  }

  return (
    <div className="min-h-screen bg-background p-6">
      <div className="max-w-4xl mx-auto">
        <div className="mb-8"></div>

        {/* Add New Comment */}
        <div className="mb-6">
          <CommentInput placeholder="What are your thoughts?" onSubmit={handleAddNewComment} userAvatar={USER_AVATAR} />
        </div>

        {/* Comments Thread */}
        <div className="space-y-0 overflow-clip">
          {comments.map((comment, index) => (
            <CommentItem
              key={comment.id}
              comment={comment}
              onEdit={handleEditComment}
              onReply={handleReplyToComment}
              level={0}
              isLast={index === comments.length - 1}
              hasNextSibling={index < comments.length - 1}
              parentConnectorHovered={false}
              getTimeDisplay={getTimeDisplay}
              userAvatar={USER_AVATAR}
            />
          ))}
        </div>

        {comments.length === 0 && (
          <Card className="p-8 text-center">
            <MessageSquare className="w-12 h-12 mx-auto mb-4 text-muted-foreground" />
            <p className="text-sm text-muted-foreground">No comments yet. Add the first comment above!</p>
          </Card>
        )}
      </div>
    </div>
  )
}
