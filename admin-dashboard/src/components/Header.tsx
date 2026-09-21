import { useSearch } from '@/contexts/SearchContext';
import { MagnifyingGlassIcon, BellIcon, QuestionMarkCircleIcon } from '@heroicons/react/24/outline';

export default function Header() {
  const { query, setQuery } = useSearch();

  return (
    <header className="fixed top-0 right-0 left-sidebar-width h-16 bg-surface-bright border-b border-border-subtle flex items-center justify-between px-margin-desktop z-40">
      <div className="flex items-center flex-1 max-w-xl">
        <div className="relative w-full">
          <MagnifyingGlassIcon className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-outline" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            className="w-full bg-surface-container-low border-none rounded-full pl-10 pr-4 py-2 text-body-md focus:ring-2 focus:ring-primary/20"
            placeholder="Rechercher des enseignements, intervenants, sujets..."
          />
        </div>
      </div>

      <div className="flex items-center gap-4">
        <button className="hover:bg-surface-container-low p-2 rounded-full transition-colors">
          <BellIcon className="w-5 h-5 text-on-surface-variant" />
        </button>
        <button className="hover:bg-surface-container-low p-2 rounded-full transition-colors">
          <QuestionMarkCircleIcon className="w-5 h-5 text-on-surface-variant" />
        </button>
        <div className="h-8 w-px bg-border-subtle mx-2" />
        <div className="flex items-center gap-3">
          <div className="text-right hidden sm:block">
            <p className="font-label-md text-label-md text-on-surface">Admin User</p>
            <p className="font-label-sm text-label-sm text-secondary">Senior Steward</p>
          </div>
          <div className="w-10 h-10 rounded-full bg-primary-fixed flex items-center justify-center text-on-primary-fixed font-bold text-sm">
            AU
          </div>
        </div>
      </div>
    </header>
  );
}
