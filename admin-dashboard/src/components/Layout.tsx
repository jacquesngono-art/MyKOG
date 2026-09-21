import { ReactNode } from 'react';
import { SearchProvider } from '@/contexts/SearchContext';
import Sidebar from './Sidebar';
import Header from './Header';

interface LayoutProps {
  children: ReactNode;
}

export default function Layout({ children }: LayoutProps) {
  return (
    <SearchProvider>
      <div className="min-h-screen bg-surface-gray">
        <Sidebar />
        <Header />
        <main className="ml-sidebar-width pt-16 min-h-screen">
          <div className="p-margin-desktop space-y-8">
            {children}
          </div>
        </main>
      </div>
    </SearchProvider>
  );
}
