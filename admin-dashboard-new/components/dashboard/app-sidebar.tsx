"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { cn } from "@/lib/utils";
import { authService } from "@/lib/services/auth";
import {
  LayoutDashboard,
  BookOpen,
  FileText,
  Megaphone,
  Radio,
  Calendar,
  Users,
  Bell,
  BarChart3,
  Settings,
  Zap,
  LogOut,
} from "lucide-react";
import type { LucideIcon } from "lucide-react";

interface NavItem {
  href: string;
  label: string;
  icon: LucideIcon;
}

const quickAccess: NavItem[] = [
  { href: "/lives", label: "Live en cours", icon: Radio },
  { href: "/notifications", label: "Envoyer une notif", icon: Bell },
];

const mainMenu: NavItem[] = [
  { href: "/", label: "Dashboard", icon: LayoutDashboard },
  { href: "/enseignements", label: "Enseignements", icon: BookOpen },
  { href: "/text-resumes", label: "Textes Résumés", icon: FileText },
  { href: "/annonces", label: "Annonces", icon: Megaphone },
  { href: "/lives", label: "Lives", icon: Radio },
  { href: "/calendar", label: "Calendrier", icon: Calendar },
  { href: "/users", label: "Utilisateurs", icon: Users },
  { href: "/notifications", label: "Notifications", icon: Bell },
  { href: "/statistiques", label: "Statistiques", icon: BarChart3 },
];

export function AppSidebar() {
  const pathname = usePathname();
  const router = useRouter();

  const logout = () => {
    authService.logout();
    router.replace("/login");
  };

  return (
    <aside className="w-[260px] h-screen bg-card border-r border-border flex flex-col shrink-0">
      {/* Logo */}
      <div className="h-16 px-5 flex items-center gap-3 border-b border-border">
        <div className="w-9 h-9 rounded-xl bg-accent flex items-center justify-center">
          <Zap className="w-5 h-5 text-accent-foreground" />
        </div>
        <span className="font-semibold text-foreground text-[15px] tracking-tight">
          MyKOG Admin
        </span>
        <span className="ml-auto px-2 py-0.5 text-[10px] font-medium bg-success/10 text-success rounded-full">
          Live
        </span>
      </div>

      {/* Quick Access */}
      <div className="px-4 py-4">
        <p className="px-2 mb-2 text-[11px] font-medium text-muted-foreground uppercase tracking-wider">
          Accès rapide
        </p>
        <nav className="space-y-0.5">
          {quickAccess.map((item) => (
            <NavButton key={item.href} item={item} isActive={false} />
          ))}
        </nav>
      </div>

      {/* Main Menu */}
      <div className="px-4 flex-1 overflow-y-auto">
        <p className="px-2 mb-2 text-[11px] font-medium text-muted-foreground uppercase tracking-wider">
          Gestion
        </p>
        <nav className="space-y-0.5">
          {mainMenu.map((item) => (
            <NavButton
              key={item.href}
              item={item}
              isActive={
                item.href === "/"
                  ? pathname === "/"
                  : pathname.startsWith(item.href)
              }
            />
          ))}
        </nav>
      </div>

      {/* Settings & User */}
      <div className="px-4 py-4 border-t border-border space-y-2">
        <NavButton
          item={{ href: "/settings", label: "Paramètres", icon: Settings }}
          isActive={pathname === "/settings"}
        />
        <div className="flex items-center gap-3 px-2 py-3 rounded-xl">
          <div className="w-9 h-9 rounded-full bg-accent/20 flex items-center justify-center">
            <span className="text-accent-foreground text-sm font-medium">A</span>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-foreground truncate">Admin</p>
            <p className="text-xs text-muted-foreground truncate">MyKOG Console</p>
          </div>
          <button
            type="button"
            onClick={logout}
            title="Se déconnecter"
            className="p-2 rounded-lg text-muted-foreground hover:text-destructive hover:bg-destructive/10 transition-colors"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </div>
    </aside>
  );
}

function NavButton({ item, isActive }: { item: NavItem; isActive: boolean }) {
  const Icon = item.icon;
  return (
    <Link
      href={item.href}
      className={cn(
        "w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm transition-all duration-200",
        "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
        isActive
          ? "bg-primary text-primary-foreground font-medium shadow-sm"
          : "text-foreground/80 hover:bg-muted/80 hover:text-foreground"
      )}
    >
      <Icon className="w-[18px] h-[18px] shrink-0" />
      <span className="flex-1 text-left">{item.label}</span>
    </Link>
  );
}
