"use client";

import { ReactNode } from "react";
import { AppSidebar } from "./app-sidebar";
import { RightPanel } from "./right-panel";
import { AuthGuard } from "@/components/auth-guard";
import { Bell, RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";

interface DashboardShellProps {
  title: string;
  subtitle: string;
  children: ReactNode;
  actions?: ReactNode;
  onRefresh?: () => void;
}

export function DashboardShell({
  title,
  subtitle,
  children,
  actions,
  onRefresh,
}: DashboardShellProps) {
  return (
    <AuthGuard>
    <div className="flex h-screen bg-background overflow-hidden">
      <AppSidebar />

      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Header */}
        <header className="h-16 px-8 flex items-center justify-between border-b border-border bg-card shrink-0">
          <div>
            <h1 className="text-lg font-semibold text-foreground tracking-tight">
              {title}
            </h1>
            <p className="text-sm text-muted-foreground">{subtitle}</p>
          </div>

          <div className="flex items-center gap-3">
            {onRefresh && (
              <Button
                variant="outline"
                size="sm"
                className="gap-2 bg-transparent"
                onClick={onRefresh}
              >
                <RefreshCw className="w-4 h-4" />
                <span>Actualiser</span>
              </Button>
            )}

            <button
              type="button"
              className="relative p-2 rounded-xl hover:bg-muted transition-colors"
              aria-label="Notifications"
            >
              <Bell className="w-5 h-5 text-muted-foreground" />
            </button>

            {actions}
          </div>
        </header>

        {/* Content */}
        <main className="flex-1 overflow-y-auto p-8">
          <div className="animate-fade-in">{children}</div>
        </main>
      </div>

      <RightPanel />
    </div>
    </AuthGuard>
  );
}
