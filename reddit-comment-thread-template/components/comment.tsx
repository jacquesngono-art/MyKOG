import { MessageCircle, Award, Share, MoreHorizontal } from "lucide-react"
import { Button } from "@/components/ui/button"

interface CommentProps {
  username: string
  timestamp: string
  content: string
  votes: number
  avatar: string
}

const UpvoteIcon = () => (
  <svg fill="currentColor" height="16" width="16" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
    <path d="M10 19c-.072 0-.145 0-.218-.006A4.1 4.1 0 0 1 6 14.816V11H2.862a1.751 1.751 0 0 1-1.234-2.993L9.41.28a.836.836 0 0 1 1.18 0l7.782 7.727A1.751 1.751 0 0 1 17.139 11H14v3.882a4.134 4.134 0 0 1-.854 2.592A3.99 3.99 0 0 1 10 19Zm0-17.193L2.685 9.071a.251.251 0 0 0 .177.429H7.5v5.316A2.63 2.63 0 0 0 9.864 17.5a2.441 2.441 0 0 0 1.856-.682A2.478 2.478 0 0 0 12.5 15V9.5h4.639a.25.25 0 0 0 .176-.429L10 1.807Z"></path>
  </svg>
)

const DownvoteIcon = () => (
  <svg fill="currentColor" height="16" width="16" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg">
    <path d="M10 1c.072 0 .145 0 .218.006A4.1 4.1 0 0 1 14 5.184V9h3.138a1.751 1.751 0 0 1 1.234 2.993L10.59 19.72a.836.836 0 0 1-1.18 0l-7.782-7.727A1.751 1.751 0 0 1 2.861 9H6V5.118a4.134 4.134 0 0 1 .854-2.592A3.99 3.99 0 0 1 10 1Zm0 17.193 7.315-7.264a.251.251 0 0 0-.177-.429H12.5V5.184A2.631 2.631 0 0 0 10.136 2.5a2.441 2.441 0 0 0-1.856.682A2.478 2.478 0 0 0 7.5 5v5.5H2.861a.251.251 0 0 0-.176.429L10 18.193Z"></path>
  </svg>
)

export function Comment({ username, timestamp, content, votes, avatar }: CommentProps) {
  return (
    <div className="flex gap-3 py-2">
      {/* Avatar */}
      <div className="flex-shrink-0">
        <img
          src={avatar || "/placeholder.svg"}
          alt={`${username}'s avatar`}
          className="w-10 h-10 rounded-full object-cover"
        />
      </div>

      {/* Comment content */}
      <div className="flex-1 min-w-0">
        {/* Header */}
        <div className="flex items-center gap-2 mb-2">
          <span className="font-medium text-foreground">{username}</span>
          <span className="text-muted-foreground">•</span>
          <span className="text-muted-foreground text-sm">{timestamp}</span>
        </div>

        {/* Comment text */}
        <div className="text-foreground mb-3">{content}</div>

        {/* Actions */}
        <div className="flex items-center gap-1">
          {/* Vote buttons */}
          <Button
            variant="ghost"
            size="sm"
            className="h-8 px-2 text-muted-foreground hover:text-orange-600 hover:bg-orange-50 rounded-full"
          >
            <UpvoteIcon />
          </Button>
          <span className="text-sm font-medium text-muted-foreground min-w-[1rem] text-center">{votes}</span>
          <Button
            variant="ghost"
            size="sm"
            className="h-8 px-2 text-muted-foreground hover:text-blue-600 hover:bg-blue-50 rounded-full"
          >
            <DownvoteIcon />
          </Button>

          {/* Action buttons */}
          <Button variant="ghost" size="sm" className="h-8 px-3 text-muted-foreground hover:text-foreground">
            <MessageCircle className="w-4 h-4 mr-1" />
            Reply
          </Button>
          <Button variant="ghost" size="sm" className="h-8 px-3 text-muted-foreground hover:text-foreground">
            <Award className="w-4 h-4 mr-1" />
            Award
          </Button>
          <Button variant="ghost" size="sm" className="h-8 px-3 text-muted-foreground hover:text-foreground">
            <Share className="w-4 h-4 mr-1" />
            Share
          </Button>
          <Button variant="ghost" size="sm" className="h-8 px-2 text-muted-foreground hover:text-foreground">
            <MoreHorizontal className="w-4 h-4" />
          </Button>
        </div>
      </div>
    </div>
  )
}
