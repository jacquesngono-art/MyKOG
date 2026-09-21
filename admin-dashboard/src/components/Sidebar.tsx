import Link from 'next/link';
import { useRouter } from 'next/router';
import {
  Squares2X2Icon,
  MicrophoneIcon,
  TvIcon,
  CalendarDaysIcon,
  DocumentTextIcon,
  FlagIcon,
  UserGroupIcon,
  ChartBarIcon,
  BellIcon,
  Cog6ToothIcon,
  ArrowRightStartOnRectangleIcon,
  BuildingLibraryIcon,
} from '@heroicons/react/24/outline';
import {
  Squares2X2Icon as Squares2X2Solid,
  MicrophoneIcon as MicrophoneSolid,
  TvIcon as TvSolid,
  CalendarDaysIcon as CalendarDaysSolid,
  DocumentTextIcon as DocumentTextSolid,
  FlagIcon as FlagSolid,
  UserGroupIcon as UserGroupSolid,
  ChartBarIcon as ChartBarSolid,
  BellIcon as BellSolid,
} from '@heroicons/react/24/solid';

const navigation = [
  { name: 'Dashboard', href: '/', icon: Squares2X2Icon, activeIcon: Squares2X2Solid },
  { name: 'Teachings', href: '/enseignements', icon: MicrophoneIcon, activeIcon: MicrophoneSolid },
  { name: 'Live Streams', href: '/lives', icon: TvIcon, activeIcon: TvSolid },
  { name: 'Calendar', href: '/calendar', icon: CalendarDaysIcon, activeIcon: CalendarDaysSolid },
  { name: 'PDF Resources', href: '/text-resumes', icon: DocumentTextIcon, activeIcon: DocumentTextSolid },
  { name: 'Annonces', href: '/annonces', icon: FlagIcon, activeIcon: FlagSolid },
  { name: 'Utilisateurs', href: '/users', icon: UserGroupIcon, activeIcon: UserGroupSolid },
  { name: 'Statistiques', href: '/statistiques', icon: ChartBarIcon, activeIcon: ChartBarSolid },
  { name: 'Notifications', href: '/notifications', icon: BellIcon, activeIcon: BellSolid },
];

const bottomNav = [
  { name: 'Settings', href: '/settings', icon: Cog6ToothIcon },
  { name: 'Logout', href: '#', icon: ArrowRightStartOnRectangleIcon },
];

export default function Sidebar() {
  const router = useRouter();

  const isActive = (href: string) => {
    if (href === '/') return router.pathname === '/';
    return router.pathname.startsWith(href);
  };

  return (
    <aside className="fixed left-0 top-0 h-screen w-sidebar-width bg-surface-container-lowest shadow-sm flex flex-col py-6 z-50">
      <div className="px-6 mb-8 flex items-center gap-3">
        <div className="w-10 h-10 bg-primary-container rounded-lg flex items-center justify-center text-on-primary-container">
          <BuildingLibraryIcon className="w-6 h-6" />
        </div>
        <div>
          <h1 className="font-headline-md text-headline-md font-bold text-on-surface">MyKOG Admin</h1>
          <p className="font-label-md text-label-md text-secondary">Stewardship Portal</p>
        </div>
      </div>

      <nav className="flex-1 space-y-1 px-4">
        {navigation.map((item) => {
          const active = isActive(item.href);
          const Icon = active ? item.activeIcon : item.icon;
          return (
            <Link
              key={item.name}
              href={item.href}
              className={`flex items-center gap-3 px-4 py-3 rounded-lg font-label-md text-label-md transition-colors duration-200 ${
                active
                  ? 'text-primary font-bold border-r-4 border-primary bg-surface-container-high'
                  : 'text-secondary hover:text-primary hover:bg-surface-container-low'
              }`}
            >
              <Icon className="w-5 h-5 shrink-0" />
              {item.name}
            </Link>
          );
        })}
      </nav>

      <div className="px-4 mt-auto space-y-1 pt-6 border-t border-border-subtle">
        {bottomNav.map((item) => (
          <Link
            key={item.name}
            href={item.href}
            className="flex items-center gap-3 px-4 py-3 rounded-lg text-secondary hover:text-primary hover:bg-surface-container-low transition-colors duration-200 font-label-md text-label-md"
          >
            <item.icon className="w-5 h-5 shrink-0" />
            {item.name}
          </Link>
        ))}
      </div>
    </aside>
  );
}
