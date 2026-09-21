const CalendarPage = {
  currentYear: new Date().getFullYear(),
  currentMonth: new Date().getMonth(),
  selectedDate: null,
  searchQuery: '',

  render() {
    const el = document.getElementById('page-calendar');
    const events = Store.state.calendarEvents || [];
    const s = Store.state;

    if (s.isLoading && !events.length) {
      el.innerHTML = `
        ${Skeleton.pageHeader()}
        ${Skeleton.eventList(4)}
      `;
      return;
    }

    const monthEvents = this.getMonthEvents(events);
    const selectedDayEvents = this.selectedDate
      ? this.getEventsForDay(monthEvents, this.selectedDate.getDate(), this.selectedDate.getMonth(), this.selectedDate.getFullYear())
      : [];

    el.innerHTML = `
      <div class="page-header">
        <h1>Calendrier</h1>
        <p>${events.length} événement${events.length !== 1 ? 's' : ''}</p>
      </div>

      ${s.isOffline ? `
        <div class="offline-banner" style="margin:0 40px 16px;">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 1l22 22M16.72 11.06A10.94 10.94 0 0119 12.55M5 12.55a10.94 10.94 0 015.17-2.39M10.71 5.05A16 16 0 0122.56 9M1.42 9a15.91 15.91 0 014.7-2.88M8.53 16.11a6 6 0 016.95 0"/></svg>
          <span>Données en cache — mode hors ligne</span>
        </div>
      ` : ''}

      <div class="calendar-layout">
        <div class="calendar-main">
          ${this.renderHeader()}
          <div class="calendar-search">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="M21 21l-4.35-4.35"/></svg>
            <input type="text" placeholder="Rechercher un événement..." value="${this.searchQuery}" oninput="CalendarPage.onSearch(this.value)">
          </div>
          ${this.renderWeekdayHeaders()}
          ${this.renderGrid(monthEvents)}
        </div>
        <div class="calendar-sidebar">
          ${this.renderDayPanel(selectedDayEvents)}
        </div>
      </div>
    `;
  },

  getMonthEvents(events) {
    const q = this.searchQuery.toLowerCase().trim();
    return events.filter(e => {
      const d = new Date(e.startDate);
      if (d.getMonth() !== this.currentMonth || d.getFullYear() !== this.currentYear) return false;
      if (!q) return true;
      return (e.title && e.title.toLowerCase().includes(q))
        || (e.category && e.category.toLowerCase().includes(q))
        || (e.location && e.location.toLowerCase().includes(q));
    });
  },

  getEventsForDay(events, day, month, year) {
    return events.filter(e => {
      const d = new Date(e.startDate);
      return d.getDate() === day && d.getMonth() === month && d.getFullYear() === year;
    });
  },

  renderHeader() {
    const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return `
      <div class="calendar-nav">
        <button class="calendar-nav-btn" onclick="CalendarPage.prevMonth()">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="15 18 9 12 15 6"/></svg>
        </button>
        <h2 class="calendar-nav-title">${months[this.currentMonth]} ${this.currentYear}</h2>
        <button class="calendar-nav-btn" onclick="CalendarPage.nextMonth()">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polyline points="9 18 15 12 9 6"/></svg>
        </button>
      </div>
    `;
  },

  renderWeekdayHeaders() {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return `
      <div class="calendar-weekdays">
        ${days.map(d => `<div class="calendar-weekday">${d}</div>`).join('')}
      </div>
    `;
  },

  renderGrid(monthEvents) {
    const firstDay = new Date(this.currentYear, this.currentMonth, 1).getDay();
    const daysInMonth = new Date(this.currentYear, this.currentMonth + 1, 0).getDate();
    const daysInPrevMonth = new Date(this.currentYear, this.currentMonth, 0).getDate();
    const today = new Date();

    const offset = firstDay === 0 ? 6 : firstDay - 1;
    let cells = [];

    for (let i = 0; i < offset; i++) {
      const day = daysInPrevMonth - offset + i + 1;
      cells.push({ day, isCurrentMonth: false });
    }

    for (let i = 1; i <= daysInMonth; i++) {
      cells.push({ day: i, isCurrentMonth: true });
    }

    const remaining = 42 - cells.length;
    for (let i = 1; i <= remaining; i++) {
      cells.push({ day: i, isCurrentMonth: false });
    }

    let html = '<div class="calendar-grid">';
    for (let i = 0; i < cells.length; i++) {
      const { day, isCurrentMonth } = cells[i];
      const isToday = isCurrentMonth
        && day === today.getDate()
        && this.currentMonth === today.getMonth()
        && this.currentYear === today.getFullYear();
      const isSelected = this.selectedDate
        && day === this.selectedDate.getDate()
        && this.currentMonth === this.selectedDate.getMonth()
        && this.currentYear === this.selectedDate.getFullYear();
      const dayEvents = isCurrentMonth ? this.getEventsForDay(monthEvents, day, this.currentMonth, this.currentYear) : [];
      html += this.renderDayCell(day, dayEvents, isCurrentMonth, isToday, isSelected);
    }
    html += '</div>';

    return html;
  },

  renderDayCell(day, events, isCurrentMonth, isToday, isSelected) {
    const classes = [
      'calendar-cell',
      isCurrentMonth ? '' : 'calendar-cell-other',
      isToday ? 'calendar-cell-today' : '',
      isSelected ? 'calendar-cell-selected' : '',
    ].filter(Boolean).join(' ');

    return `
      <div class="${classes}" onclick="CalendarPage.selectDate(${isCurrentMonth ? `new Date(${this.currentYear}, ${this.currentMonth}, ${day})` : 'null'})">
        <span class="calendar-cell-day">${day}</span>
        ${events.length > 0 ? `
          <div class="calendar-dots">
            ${events.slice(0, 3).map(e => {
              const color = this.getCategoryColor(e.category);
              return `<div class="calendar-dot" style="background:${color};"></div>`;
            }).join('')}
            ${events.length > 3 ? `<span class="calendar-dot-more">+${events.length - 3}</span>` : ''}
          </div>
        ` : ''}
      </div>
    `;
  },

  renderDayPanel(events) {
    if (!this.selectedDate) {
      return `
        <div class="day-panel-empty">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color:var(--text-tertiary);"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>
          <p>Sélectionnez un jour<br>pour voir les événements</p>
        </div>
      `;
    }

    const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    const dateStr = `${this.selectedDate.getDate()} ${months[this.selectedDate.getMonth()]} ${this.selectedDate.getFullYear()}`;

    return `
      <div class="day-panel-header">
        <h3>${dateStr}</h3>
        <span class="day-panel-count">${events.length} événement${events.length !== 1 ? 's' : ''}</span>
      </div>
      ${events.length === 0 ? `
        <div class="day-panel-empty">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" style="color:var(--text-tertiary);"><circle cx="12" cy="12" r="10"/><path d="M12 8v4l3 3"/></svg>
          <p>Aucun événement ce jour</p>
        </div>
      ` : `
        <div class="day-panel-events">
          ${events.map(e => this.renderEventCard(e)).join('')}
        </div>
      `}
    `;
  },

  renderEventCard(event) {
    const color = this.getCategoryColor(event.category);
    const start = new Date(event.startDate);
    const end = event.endDate ? new Date(event.endDate) : null;

    const hours = start.getHours().toString().padStart(2, '0');
    const mins = start.getMinutes().toString().padStart(2, '0');
    const endHours = end ? end.getHours().toString().padStart(2, '0') : '';
    const endMins = end ? end.getMinutes().toString().padStart(2, '0') : '';

    return `
      <div class="day-panel-event" style="border-left-color:${color};">
        <p class="day-panel-event-title">${event.title}</p>
        <p class="day-panel-event-time">
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          ${hours}:${mins}${end ? ` — ${endHours}:${endMins}` : ''}
        </p>
        ${event.location ? `<p class="day-panel-event-location"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z"/><circle cx="12" cy="10" r="3"/></svg>${event.location}</p>` : ''}
        ${event.description ? `<p class="day-panel-event-desc">${event.description}</p>` : ''}
        ${event.category ? `<span class="day-panel-event-tag" style="background:${color}22;color:${color};">${event.category}</span>` : ''}
      </div>
    `;
  },

  getCategoryColor(category) {
    const palette = {
      'Culte': '#d4af37',
      'Enseignement': '#3b82f6',
      'Louange': '#8b5cf6',
      'Jeûne': '#f59e0b',
      'Prières': '#1db954',
      'Conférence': '#ef4444',
      'Réunion': '#14b8a6',
      'default': '#d4af37',
    };
    if (!category) return palette.default;
    for (const key of Object.keys(palette)) {
      if (category.toLowerCase().includes(key.toLowerCase())) return palette[key];
    }
    return palette.default;
  },

  selectDate(date) {
    this.selectedDate = date;
    this.render();
  },

  prevMonth() {
    this.currentMonth--;
    if (this.currentMonth < 0) {
      this.currentMonth = 11;
      this.currentYear--;
    }
    this.selectedDate = null;
    this.render();
  },

  nextMonth() {
    this.currentMonth++;
    if (this.currentMonth > 11) {
      this.currentMonth = 0;
      this.currentYear++;
    }
    this.selectedDate = null;
    this.render();
  },

  onSearch(value) {
    this.searchQuery = value;
    this.render();
  },
};
