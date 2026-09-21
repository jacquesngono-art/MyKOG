import { useState, useEffect } from 'react';
import { usersService } from '../../lib/services/users';
import type { User } from '../../lib/types';

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadUsers();
  }, []);

  async function loadUsers() {
    try {
      const data = await usersService.getAll();
      setUsers(data);
    } catch (err) {
      console.error('Erreur chargement utilisateurs:', err);
    } finally {
      setLoading(false);
    }
  }

  return (
    <>
      <div className="flex justify-between items-end mb-8">
        <div>
          <h2 className="font-headline-lg text-headline-lg text-on-surface mb-1">Utilisateurs</h2>
          <p className="font-body-lg text-body-lg text-secondary">Gestion des utilisateurs de la plateforme.</p>
        </div>
      </div>

      <div className="bg-surface-container-lowest rounded-xl border border-border-subtle overflow-hidden">
        {loading ? (
          <div className="p-8 text-center text-secondary">Chargement...</div>
        ) : users.length === 0 ? (
          <div className="p-8 text-center text-secondary">Aucun utilisateur</div>
        ) : (
        <table className="w-full">
          <thead>
            <tr className="bg-surface-container-low border-b border-border-subtle">
              <th className="px-6 py-4 text-left font-label-md text-label-md text-secondary uppercase">Nom</th>
              <th className="px-6 py-4 text-left font-label-md text-label-md text-secondary uppercase">Email</th>
              <th className="px-6 py-4 text-left font-label-md text-label-md text-secondary uppercase">Favoris</th>
              <th className="px-6 py-4 text-left font-label-md text-label-md text-secondary uppercase">Notifications</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-border-subtle">
            {users.map((u) => (
              <tr key={u.id} className="hover:bg-surface-container-low/50">
                <td className="px-6 py-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-full bg-primary-fixed text-primary flex items-center justify-center font-bold">
                      {u.name?.charAt(0)?.toUpperCase() || '?'}
                    </div>
                    <span className="font-body-md text-body-md text-on-surface">{u.name}</span>
                  </div>
                </td>
                <td className="px-6 py-4 font-body-md text-body-md text-secondary">{u.email}</td>
                <td className="px-6 py-4">
                  <span className="bg-primary-fixed text-on-primary-fixed px-3 py-1 rounded-full font-label-sm">{u.favoriteTeachingIds?.length || 0}</span>
                </td>
                <td className="px-6 py-4">
                  <span className={`flex items-center gap-1.5 font-label-sm ${u.notificationsEnabled ? 'text-status-success' : 'text-secondary'}`}>
                    <span className={`w-2 h-2 rounded-full ${u.notificationsEnabled ? 'bg-status-success' : 'bg-outline'}`} />
                    {u.notificationsEnabled ? 'Activées' : 'Désactivées'}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        )}
      </div>
    </>
  );
}
