export default function SettingsPage() {
  return (
    <>
      <div className="mb-8">
        <h2 className="font-headline-lg text-headline-lg text-on-surface mb-1">Settings</h2>
        <p className="font-body-lg text-body-lg text-secondary">Configuration de la plateforme.</p>
      </div>

      <div className="bg-surface-container-lowest rounded-xl shadow-sm border border-border-subtle p-6 max-w-lg space-y-6">
        <div>
          <label className="block font-label-md text-label-md text-secondary mb-2">API URL</label>
          <input className="w-full px-4 py-3 rounded-lg border border-border-subtle font-mono text-body-md" defaultValue={process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api'} readOnly />
        </div>
        <div>
          <label className="block font-label-md text-label-md text-secondary mb-2">Platform Name</label>
          <input className="w-full px-4 py-3 rounded-lg border border-border-subtle font-body-md" defaultValue="MyKOG Admin" />
        </div>
        <button className="bg-primary text-on-primary px-6 py-3 rounded-lg font-label-md">Save Settings</button>
      </div>
    </>
  );
}
