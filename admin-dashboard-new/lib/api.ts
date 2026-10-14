const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api';
const TIMEOUT = 30000;
const UPLOAD_TIMEOUT = 600000; // 10 min — les fichiers audio/vidéo volumineux montent lentement

export class ApiClient {
  private base: string;

  constructor(base = API_BASE) {
    this.base = base;
  }

  private async req<T>(path: string, opts: RequestInit = {}): Promise<T> {
    const ctrl = new AbortController();
    const id = setTimeout(() => ctrl.abort(), TIMEOUT);
    try {
      const res = await fetch(`${this.base}${path}`, { ...opts, signal: ctrl.signal });
      clearTimeout(id);
      if (!res.ok) {
        const err = await res.json().catch(() => ({ error: res.statusText }));
        throw new Error(err.error || `HTTP ${res.status}`);
      }
      return res.json();
    } catch (e: any) {
      clearTimeout(id);
      if (e.name === 'AbortError') throw new Error('Request timeout');
      throw e;
    }
  }

  get<T>(path: string) { return this.req<T>(path); }
  post<T>(path: string, data?: any, formData = false) {
    return this.req<T>(path, {
      method: 'POST',
      ...(formData ? { body: data } : { headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data) }),
    });
  }
  put<T>(path: string, data?: any, formData = false) {
    return this.req<T>(path, {
      method: 'PUT',
      ...(formData ? { body: data } : { headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data) }),
    });
  }
  delete<T>(path: string, data?: any) {
    return this.req<T>(path, {
      method: 'DELETE',
      ...(data ? { headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data) } : {}),
    });
  }

  upload<T>(path: string, formData: FormData, onProgress?: (pct: number) => void): Promise<T> {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      const url = `${this.base}${path}`;
      xhr.open('POST', url);

      const timeoutId = setTimeout(() => { xhr.abort(); reject(new Error('Upload trop long (10 min max)')); }, UPLOAD_TIMEOUT);

      xhr.upload.onprogress = (e) => {
        if (e.lengthComputable && onProgress) {
          onProgress(Math.round((e.loaded / e.total) * 100));
        }
      };

      xhr.onload = () => {
        clearTimeout(timeoutId);
        try {
          const res = JSON.parse(xhr.responseText);
          if (xhr.status >= 200 && xhr.status < 300) resolve(res);
          else reject(new Error(res.error || `HTTP ${xhr.status}`));
        } catch {
          reject(new Error('Invalid response'));
        }
      };

      xhr.onerror = () => { clearTimeout(timeoutId); reject(new Error('Network error')); };
      xhr.onabort = () => { clearTimeout(timeoutId); reject(new Error('Request aborted')); };

      xhr.send(formData);
    });
  }
}

export const api = new ApiClient();
