/* ==========================================
   PAINEL MÉDICO - BV Dev
   JavaScript Application
   ========================================== */

const App = {
    data: null,
    currentPage: 'dashboard',
    searchedPassport: null,
    diagnostics: [],
    orçamentotions: [],
    attendances: [],

    // ========== INIT ==========
    init() {
        this.bindNavigation();
        this.bindModals();
        this.bindSearch();
        this.bindChat();
        this.bindDiagnostics();
        this.bindOrçamentotions();
        this.bindAttendances();
        this.bindStaff();
        this.bindPrescription();
        this.bindHealthPlan();
        this.bindClose();

        window.addEventListener('message', (e) => this.onMessage(e));
        window.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                const openModal = document.querySelector('.modal:not(.hidden)');
                if (openModal) {
                    this.closeModal(openModal.id);
                } else {
                    this.close();
                }
            }
        });
    },

    // ========== NUI MESSAGE HANDLER ==========
    onMessage(event) {
        const msg = event.data;
        switch (msg.action) {
            case 'open':
                this.data = msg.data;
                this.show();
                this.renderDashboard();
                break;
            case 'close':
                this.hide();
                break;
            case 'receiveSearch':
                this.renderSearchResults(msg.data);
                break;
            case 'receiveChat':
                this.appendChatMessage(msg.data);
                break;
            case 'receiveOrçamentotions':
                this.orçamentotions = msg.data || [];
                this.renderOrçamentotionsPage();
                break;
            case 'receiveAttendances':
                this.attendances = msg.data || [];
                this.renderAttendancesPage();
                break;
            case 'receiveDiagnostics':
                this.diagnostics = msg.data || [];
                this.renderDiagnosticsPage();
                break;
            case 'notification':
                // notifications handled by client-side creative_notify
                break;
        }
    },

    // ========== SHOW / HIDE ==========
    show() {
        document.getElementById('med-container').classList.remove('hidden');
        if (this.data) {
            document.getElementById('sidebar-user-name').textContent = this.data.myName || 'Mecânico';
            document.getElementById('sidebar-user-rank').textContent = this.data.myRole || 'Cargo';
        }
    },

    hide() {
        document.getElementById('med-container').classList.add('hidden');
    },

    close() {
        this.hide();
        fetch('https://Painel_Mecanica/close', { method: 'POST', body: JSON.stringify({}) });
    },

    // ========== NAVIGATION ==========
    bindNavigation() {
        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const page = btn.dataset.page;
                this.navigateTo(page);
            });
        });
    },

    navigateTo(page) {
        this.currentPage = page;

        document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
        document.querySelector(`.nav-btn[data-page="${page}"]`)?.classList.add('active');

        document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
        document.getElementById(`page-${page}`)?.classList.add('active');

        // Load data for specific pages
        if (page === 'diagnosticos') {
            fetch('https://Painel_Mecanica/getDiagnostics', { method: 'POST', body: JSON.stringify({}) });
        } else if (page === 'orçamentos') {
            fetch('https://Painel_Mecanica/getOrçamentotions', { method: 'POST', body: JSON.stringify({}) });
        } else if (page === 'guinchos') {
            fetch('https://Painel_Mecanica/getAttendances', { method: 'POST', body: JSON.stringify({}) });
        } else if (page === 'funcionarios') {
            this.renderStaffPage();
        }
    },

    // ========== CLOSE ==========
    bindClose() {
        document.getElementById('btn-close').addEventListener('click', () => this.close());
    },

    // ========== DASHBOARD ==========
    renderDashboard() {
        if (!this.data) return;
        const s = this.data.stats || {};

        document.getElementById('stat-diagnosticos').textContent = s.diagnostics || 0;
        document.getElementById('stat-orçamentos').textContent = s.orçamentotions || 0;
        document.getElementById('stat-guinchos').textContent = s.attendances || 0;
        document.getElementById('stat-medicos').textContent = s.medicsOnline || 0;
        document.getElementById('pending-count').textContent = s.pending || 0;

        // Recent diagnostics
        const diagList = document.getElementById('dashboard-diags-list');
        if (this.data.recentDiags && this.data.recentDiags.length > 0) {
            diagList.innerHTML = this.data.recentDiags.map(d => `
                <div class="dash-item">
                    <div class="dash-item-icon"><i class="fas fa-tags"></i></div>
                    <div class="dash-item-info">
                        <span class="name">${this.esc(d.patient_name)}</span>
                        <span class="desc">${this.truncate(d.diagnosis, 50)}</span>
                    </div>
                    <span class="dash-item-time">${this.formatDate(d.created_at)}</span>
                </div>
            `).join('');
        } else {
            diagList.innerHTML = `<div class="empty-state"><i class="fas fa-tags"></i><p>Nenhum serviço realizado recente</p></div>`;
        }

        // Pending attendances
        const pendingList = document.getElementById('dashboard-pending-list');
        if (this.data.pendingAttendances && this.data.pendingAttendances.length > 0) {
            pendingList.innerHTML = this.data.pendingAttendances.map(a => `
                <div class="dash-item">
                    <div class="dash-item-icon" style="background:${a.status === 'Pendente' ? 'var(--accent-orange-light)' : 'var(--primary-light)'}; color:${a.status === 'Pendente' ? 'var(--accent-orange)' : 'var(--primary)'}">
                        <i class="fas fa-${a.status === 'Pendente' ? 'exclamation-triangle' : 'spinner'}"></i>
                    </div>
                    <div class="dash-item-info">
                        <span class="name">${this.esc(a.patient_name)}</span>
                        <span class="desc">${this.truncate(a.reason || 'Sem motivo', 40)} - ${this.esc(a.location || '')}</span>
                    </div>
                    <span class="status-badge ${a.status === 'Pendente' ? 'orange' : 'blue'}">${a.status}</span>
                </div>
            `).join('');
        } else {
            pendingList.innerHTML = `<div class="empty-state"><i class="fas fa-check-circle"></i><p>Nenhum chamado pendente!</p></div>`;
        }

        // Chat messages
        this.renderChatMessages(this.data.chat || []);
    },

    // ========== CHAT ==========
    renderChatMessages(messages) {
        const container = document.getElementById('chat-messages');
        if (!messages.length) {
            container.innerHTML = `<div class="empty-state"><i class="fas fa-comment-slash"></i><p>Nenhuma mensagem</p></div>`;
            return;
        }
        container.innerHTML = messages.map(m => `
            <div class="chat-message">
                <div class="chat-avatar"><i class="fas fa-user"></i></div>
                <div class="chat-bubble">
                    <span class="chat-name">${this.esc(m.name)}</span>
                    <span class="chat-text">${this.esc(m.message)}</span>
                    <span class="chat-time">${this.formatDate(m.created_at)}</span>
                </div>
            </div>
        `).join('');
        container.scrollTop = container.scrollHeight;
    },

    appendChatMessage(msg) {
        const container = document.getElementById('chat-messages');
        const empty = container.querySelector('.empty-state');
        if (empty) empty.remove();

        const div = document.createElement('div');
        div.className = 'chat-message';
        div.innerHTML = `
            <div class="chat-avatar"><i class="fas fa-user"></i></div>
            <div class="chat-bubble">
                <span class="chat-name">${this.esc(msg.name)}</span>
                <span class="chat-text">${this.esc(msg.message)}</span>
                <span class="chat-time">${this.formatDate(msg.created_at)}</span>
            </div>
        `;
        container.appendChild(div);
        container.scrollTop = container.scrollHeight;
    },

    bindChat() {
        const input = document.getElementById('chat-input');
        const btn = document.getElementById('btn-send-chat');

        const sendChat = () => {
            const msg = input.value.trim();
            if (!msg) return;
            fetch('https://Painel_Mecanica/sendChat', { method: 'POST', body: JSON.stringify({ message: msg }) });
            input.value = '';
        };

        btn.addEventListener('click', sendChat);
        input.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') sendChat();
        });
    },

    // ========== SEARCH ==========
    bindSearch() {
        // Câmera - Tirar foto 3x4
        document.getElementById('patient-avatar-btn').addEventListener('click', () => {
            if (!this.searchedPassport) return;
            fetch('https://Painel_Mecanica/openCamera', { method: 'POST', body: JSON.stringify({ passport: this.searchedPassport }) });
        });

        document.getElementById('btn-search').addEventListener('click', () => this.doSearch());
        document.getElementById('search-passport').addEventListener('keydown', (e) => {
            if (e.key === 'Enter') this.doSearch();
        });

        // Result tabs
        document.querySelectorAll('.result-tabs .tab-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                const tab = btn.dataset.tab;
                document.querySelectorAll('.result-tabs .tab-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                document.querySelectorAll('.tab-content').forEach(tc => tc.classList.remove('active'));
                document.getElementById(`tab-${tab}`)?.classList.add('active');
            });
        });

        // Action buttons
        document.getElementById('btn-diagnosticar').addEventListener('click', () => {
            if (this.searchedPassport) {
                document.getElementById('diag-patient').value = this.searchedPassport;
            }
            this.openModal('modal-diagnostico');
        });

        document.getElementById('btn-orçamento').addEventListener('click', () => {
            if (this.searchedPassport) {
                document.getElementById('consult-patient').value = this.searchedPassport;
            }
            this.populateSpecialties('consult-specialty');
            this.openModal('modal-orçamento');
        });


    },

    doSearch() {
        const passport = document.getElementById('search-passport').value.trim();
        if (!passport) return;
        this.searchedPassport = parseInt(passport);
        document.getElementById('search-results').classList.add('hidden');
        fetch('https://Painel_Mecanica/searchPatient', { method: 'POST', body: JSON.stringify({ passport: passport }) });
    },

    renderSearchResults(data) {
        if (!data) return;

        document.getElementById('search-results').classList.remove('hidden');

        document.getElementById('patient-name').textContent = data.name || '-';
        document.getElementById('patient-passport').textContent = data.passport || '-';
        document.getElementById('patient-registration').textContent = data.registration || '-';
        document.getElementById('patient-age').textContent = data.age ? data.age + ' anos' : '-';
        document.getElementById('patient-phone').textContent = data.phone || '-';
        if (document.getElementById('patient-blood')) {
            document.getElementById('patient-blood').textContent = data.bloodLabel || '-';
        }
        document.getElementById('patient-sex').textContent = data.sex === 'M' || data.sex === 'male' ? 'Masculino' : 'Feminino';
        this.searchedPassport = data.passport;

        // Health plan
        const hpEl = document.getElementById('patient-healthplan');
        if (hpEl) {
            if (data.healthplan && data.healthplan.length > 0 && data.healthplan[0].active) {
                hpEl.textContent = data.healthplan[0].plan_type;
                hpEl.style.color = 'var(--primary)';
            } else {
                hpEl.textContent = 'Não possui';
                hpEl.style.color = 'var(--text-muted)';
            }
        }

        // Mugshot
        const photoEl = document.getElementById('patient-photo');
        if (data.linked_image && data.linked_image.length > 10) {
            // Suportar ambos formatos: com e sem prefixo data URI
            photoEl.src = data.linked_image.startsWith('data:') ? data.linked_image : 'data:image/jpeg;base64,' + data.linked_image;
            photoEl.style.display = 'block';
        } else {
            photoEl.style.display = 'none';
        }

        // Diagnostics history
        const diagTbody = document.getElementById('hist-diag-tbody');
        if (data.diagnostics && data.diagnostics.length > 0) {
            diagTbody.innerHTML = data.diagnostics.map(d => `
                <tr>
                    <td>${this.formatDate(d.created_at)}</td>
                    <td>${this.esc(d.doctor_name)}</td>
                    <td><span class="truncate">${this.esc(d.diagnosis)}</span></td>
                    <td>${this.statusBadge(d.status)}</td>
                </tr>
            `).join('');
        } else {
            diagTbody.innerHTML = '<tr><td colspan="4" style="text-align:center;color:var(--text-muted);padding:20px">Nenhum serviço realizado encontrado</td></tr>';
        }

        // Orçamentotions history
        const consultTbody = document.getElementById('hist-consult-tbody');
        if (data.orçamentotions && data.orçamentotions.length > 0) {
            consultTbody.innerHTML = data.orçamentotions.map(c => `
                <tr>
                    <td>${this.formatDate(c.created_at)}</td>
                    <td>${this.esc(c.specialty)}</td>
                    <td>${this.esc(c.doctor_name)}</td>
                    <td>${this.statusBadge(c.status)}</td>
                </tr>
            `).join('');
        } else {
            consultTbody.innerHTML = '<tr><td colspan="4" style="text-align:center;color:var(--text-muted);padding:20px">Nenhuma orçamento encontrada</td></tr>';
        }

        // Prescriptions history
        const receitasTbody = document.getElementById('hist-receitas-tbody');
        if (receitasTbody) {
            if (data.prescriptions && data.prescriptions.length > 0) {
                receitasTbody.innerHTML = data.prescriptions.map(p => `
                    <tr>
                        <td>${this.formatDate(p.created_at)}</td>
                        <td>${this.esc(p.doctor_name)}</td>
                        <td>${this.esc(p.medication)}</td>
                        <td>${this.esc(p.dosage)}</td>
                    </tr>
                `).join('');
            } else {
                receitasTbody.innerHTML = '<tr><td colspan="4" style="text-align:center;color:var(--text-muted);padding:20px">Nenhuma receita encontrada</td></tr>';
            }
        }
    },

    // ========== DIAGNOSTICS PAGE ==========
    bindDiagnostics() {
        document.getElementById('btn-novo-diag').addEventListener('click', () => {
            document.getElementById('diag-patient').value = '';
            document.getElementById('diag-diagnosis').value = '';
            document.getElementById('diag-treatment').value = '';
            this.openModal('modal-diagnostico');
        });

        document.getElementById('btn-confirm-diag').addEventListener('click', () => {
            const patient = document.getElementById('diag-patient').value.trim();
            const diagnosis = document.getElementById('diag-diagnosis').value.trim();
            const treatment = document.getElementById('diag-treatment').value.trim();

            if (!patient || !diagnosis) return;

            fetch('https://Painel_Mecanica/createDiagnostic', {
                method: 'POST',
                body: JSON.stringify({
                    patient_passport: patient,
                    diagnosis: diagnosis,
                    treatment: treatment
                })
            });

            this.closeModal('modal-diagnostico');
            setTimeout(() => {
                fetch('https://Painel_Mecanica/getDiagnostics', { method: 'POST', body: JSON.stringify({}) });
                if (this.searchedPassport) {
                    fetch('https://Painel_Mecanica/searchPatient', { method: 'POST', body: JSON.stringify({ passport: this.searchedPassport }) });
                }
            }, 500);
        });

        // Filter
        document.getElementById('diag-filter').addEventListener('change', () => this.renderDiagnosticsPage());
        document.getElementById('diag-search').addEventListener('input', () => this.renderDiagnosticsPage());
    },

    renderDiagnosticsPage() {
        const filter = document.getElementById('diag-filter').value;
        const search = document.getElementById('diag-search').value.toLowerCase();

        let filtered = this.diagnostics;
        if (filter !== 'all') {
            filtered = filtered.filter(d => d.status === filter);
        }
        if (search) {
            filtered = filtered.filter(d =>
                (d.patient_name || '').toLowerCase().includes(search) ||
                (d.diagnosis || '').toLowerCase().includes(search) ||
                (d.doctor_name || '').toLowerCase().includes(search)
            );
        }

        const tbody = document.getElementById('diag-tbody');
        if (filtered.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--text-muted);padding:30px">Nenhum serviço realizado encontrado</td></tr>';
            return;
        }

        tbody.innerHTML = filtered.map(d => `
            <tr>
                <td>${this.formatDate(d.created_at)}</td>
                <td>${this.esc(d.patient_name)}</td>
                <td>${this.esc(d.doctor_name)}</td>
                <td><span class="truncate">${this.esc(d.diagnosis)}</span></td>
                <td>${this.statusBadge(d.status)}</td>
                <td>
                    ${d.status === 'Em peças instaladas' ? `
                        <button class="table-action complete" title="Concluir" onclick="App.updateDiagnostic(${d.id}, 'Concluído')"><i class="fas fa-check"></i></button>
                    ` : ''}
                </td>
            </tr>
        `).join('');
    },

    updateDiagnostic(id, status) {
        fetch('https://Painel_Mecanica/updateDiagnostic', {
            method: 'POST',
            body: JSON.stringify({ id: id, status: status })
        });
        setTimeout(() => {
            fetch('https://Painel_Mecanica/getDiagnostics', { method: 'POST', body: JSON.stringify({}) });
        }, 400);
    },

    // ========== CONSULTATIONS PAGE ==========
    bindOrçamentotions() {
        document.getElementById('btn-nova-orçamento').addEventListener('click', () => {
            document.getElementById('consult-patient').value = '';
            document.getElementById('consult-date').value = '';
            document.getElementById('consult-notes').value = '';
            this.populateSpecialties('consult-specialty');
            this.openModal('modal-orçamento');
        });

        document.getElementById('btn-confirm-consult').addEventListener('click', () => {
            const patient = document.getElementById('consult-patient').value.trim();
            const specialty = document.getElementById('consult-specialty').value;
            const date = document.getElementById('consult-date').value.trim();
            const notes = document.getElementById('consult-notes').value.trim();

            if (!patient || !specialty) return;

            fetch('https://Painel_Mecanica/createOrçamentotion', {
                method: 'POST',
                body: JSON.stringify({
                    patient_passport: patient,
                    specialty: specialty,
                    scheduled_date: date,
                    notes: notes
                })
            });

            this.closeModal('modal-orçamento');
            setTimeout(() => {
                fetch('https://Painel_Mecanica/getOrçamentotions', { method: 'POST', body: JSON.stringify({}) });
            }, 500);
        });

        document.getElementById('consult-filter').addEventListener('change', () => this.renderOrçamentotionsPage());
        document.getElementById('consult-search').addEventListener('input', () => this.renderOrçamentotionsPage());
    },

    renderOrçamentotionsPage() {
        const filter = document.getElementById('consult-filter').value;
        const search = document.getElementById('consult-search').value.toLowerCase();

        let filtered = this.orçamentotions;
        if (filter !== 'all') {
            filtered = filtered.filter(c => c.status === filter);
        }
        if (search) {
            filtered = filtered.filter(c =>
                (c.patient_name || '').toLowerCase().includes(search) ||
                (c.specialty || '').toLowerCase().includes(search) ||
                (c.doctor_name || '').toLowerCase().includes(search)
            );
        }

        const tbody = document.getElementById('consult-tbody');
        if (filtered.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--text-muted);padding:30px">Nenhuma orçamento encontrada</td></tr>';
            return;
        }

        tbody.innerHTML = filtered.map(c => `
            <tr>
                <td>${this.esc(c.patient_name)}</td>
                <td>${this.esc(c.specialty)}</td>
                <td>${this.esc(c.scheduled_date || '-')}</td>
                <td>${this.esc(c.doctor_name)}</td>
                <td>${this.statusBadge(c.status)}</td>
                <td>
                    ${c.status === 'Agendada' ? `
                        <button class="table-action complete" title="Marcar como Realizada" onclick="App.updateOrçamentotion(${c.id}, 'Realizada')"><i class="fas fa-check"></i></button>
                        <button class="table-action cancel" title="Cancelar" onclick="App.updateOrçamentotion(${c.id}, 'Cancelada')"><i class="fas fa-times"></i></button>
                    ` : ''}
                </td>
            </tr>
        `).join('');
    },

    updateOrçamentotion(id, status) {
        fetch('https://Painel_Mecanica/updateOrçamentotion', {
            method: 'POST',
            body: JSON.stringify({ id: id, status: status })
        });
        setTimeout(() => {
            fetch('https://Painel_Mecanica/getOrçamentotions', { method: 'POST', body: JSON.stringify({}) });
        }, 400);
    },

    populateSpecialties(selectId) {
        const sel = document.getElementById(selectId);
        sel.innerHTML = '<option value="">Selecione...</option>';
        if (this.data && this.data.specialties) {
            this.data.specialties.forEach(s => {
                const opt = document.createElement('option');
                opt.value = s;
                opt.textContent = s;
                sel.appendChild(opt);
            });
        }
    },

    // ========== PRESCRIPTIONS ==========
    bindPrescription() {
        document.getElementById('btn-confirm-receita').addEventListener('click', () => {
            const patient = document.getElementById('receita-patient').value.trim();
            const medication = document.getElementById('receita-medication').value.trim();
            const dosage = document.getElementById('receita-dosage').value.trim();
            const notes = document.getElementById('receita-notes').value.trim();

            if (!patient || !medication) return;

            fetch('https://Painel_Mecanica/createPrescription', {
                method: 'POST',
                body: JSON.stringify({
                    patient_passport: patient,
                    medication: medication,
                    dosage: dosage,
                    notes: notes
                })
            });

            this.closeModal('modal-receita');
            if (this.searchedPassport) {
                setTimeout(() => {
                    fetch('https://Painel_Mecanica/searchPatient', { method: 'POST', body: JSON.stringify({ passport: this.searchedPassport }) });
                }, 500);
            }
        });
    },

    // ========== HEALTH PLAN ==========
    bindHealthPlan() {
        document.getElementById('btn-confirm-plano').addEventListener('click', () => {
            if (!this.searchedPassport) return;
            const planType = document.getElementById('plano-type').value;

            fetch('https://Painel_Mecanica/grantHealthPlan', {
                method: 'POST',
                body: JSON.stringify({ passport: this.searchedPassport, plan_type: planType })
            });

            this.closeModal('modal-plano');
            setTimeout(() => {
                fetch('https://Painel_Mecanica/searchPatient', { method: 'POST', body: JSON.stringify({ passport: this.searchedPassport }) });
            }, 500);
        });

        document.getElementById('btn-remove-plano').addEventListener('click', () => {
            if (!this.searchedPassport) return;

            fetch('https://Painel_Mecanica/removeHealthPlan', {
                method: 'POST',
                body: JSON.stringify({ passport: this.searchedPassport })
            });

            this.closeModal('modal-plano');
            setTimeout(() => {
                fetch('https://Painel_Mecanica/searchPatient', { method: 'POST', body: JSON.stringify({ passport: this.searchedPassport }) });
            }, 500);
        });
    },

    openHealthPlanModal() {
        if (!this.searchedPassport) return;

        const infoEl = document.getElementById('plano-status-info');
        const removeBtn = document.getElementById('btn-remove-plano');
        const typeGroup = document.getElementById('plano-type-group');

        // Check current health plan from search results
        const hpText = document.getElementById('patient-healthplan').textContent;
        if (hpText && hpText !== 'Não possui') {
            infoEl.className = 'has-plan';
            infoEl.innerHTML = `<i class="fas fa-shield-alt"></i> Cliente já possui plano: <b>${hpText}</b>`;
            removeBtn.style.display = 'inline-flex';
            typeGroup.style.display = 'block';
        } else {
            infoEl.className = 'no-plan';
            infoEl.innerHTML = `<i class="fas fa-info-circle"></i> Cliente não possui plano de saúde.`;
            removeBtn.style.display = 'none';
            typeGroup.style.display = 'block';
        }

        this.openModal('modal-plano');
    },

    // ========== ATTENDANCES PAGE ==========
    bindAttendances() {
        document.getElementById('btn-novo-attend').addEventListener('click', () => {
            document.getElementById('attend-patient').value = '';
            document.getElementById('attend-reason').value = '';
            document.getElementById('attend-location').value = '';
            this.openModal('modal-guincho');
        });

        document.getElementById('btn-confirm-attend').addEventListener('click', () => {
            const patient = document.getElementById('attend-patient').value.trim();
            const reason = document.getElementById('attend-reason').value.trim();
            const location = document.getElementById('attend-location').value.trim();

            if (!patient) return;

            fetch('https://Painel_Mecanica/createAttendance', {
                method: 'POST',
                body: JSON.stringify({
                    patient_passport: patient,
                    reason: reason,
                    location: location
                })
            });

            this.closeModal('modal-guincho');
            setTimeout(() => {
                fetch('https://Painel_Mecanica/getAttendances', { method: 'POST', body: JSON.stringify({}) });
                fetch('https://Painel_Mecanica/refreshData', { method: 'POST', body: JSON.stringify({}) });
            }, 500);
        });
    },

    renderAttendancesPage() {
        const grid = document.getElementById('attend-grid');

        if (!this.attendances || this.attendances.length === 0) {
            grid.innerHTML = `<div class="empty-state"><i class="fas fa-check-circle"></i><p>Nenhum chamado pendente!</p></div>`;
            return;
        }

        grid.innerHTML = this.attendances.map(a => {
            const isPending = a.status === 'Pendente';
            const isActive = a.status === 'Em andamento';
            const isDone = a.status === 'Concluído';

            return `
                <div class="attend-card ${isActive ? 'active' : ''} ${isDone ? 'completed' : ''}">
                    <div class="attend-head">
                        <span class="attend-patient"><i class="fas fa-user"></i> ${this.esc(a.patient_name)}</span>
                        ${this.statusBadge(a.status)}
                    </div>
                    <div class="attend-reason">${this.esc(a.reason || 'Sem motivo informado')}</div>
                    ${a.location ? `<div class="attend-location"><i class="fas fa-map-marker-alt"></i> ${this.esc(a.location)}</div>` : ''}
                    ${a.doctor_name && !isPending ? `<div class="attend-doctor"><i class="fas fa-wrench"></i> ${this.esc(a.doctor_name)}</div>` : ''}
                    <div class="attend-time"><i class="fas fa-clock"></i> ${this.formatDate(a.created_at)}</div>
                    <div class="attend-actions">
                        ${isPending ? `<button class="btn btn-primary btn-sm" onclick="App.claimAttendance(${a.id})"><i class="fas fa-hand-paper"></i> Assumir</button>` : ''}
                        ${isActive ? `<button class="btn btn-primary btn-sm" onclick="App.completeAttendance(${a.id})"><i class="fas fa-check"></i> Concluir</button>` : ''}
                    </div>
                </div>
            `;
        }).join('');
    },

    claimAttendance(id) {
        fetch('https://Painel_Mecanica/claimAttendance', { method: 'POST', body: JSON.stringify({ id: id }) });
        setTimeout(() => {
            fetch('https://Painel_Mecanica/getAttendances', { method: 'POST', body: JSON.stringify({}) });
        }, 400);
    },

    completeAttendance(id) {
        fetch('https://Painel_Mecanica/completeAttendance', { method: 'POST', body: JSON.stringify({ id: id }) });
        setTimeout(() => {
            fetch('https://Painel_Mecanica/getAttendances', { method: 'POST', body: JSON.stringify({}) });
        }, 400);
    },

    // ========== STAFF PAGE ==========
    bindStaff() {
        document.getElementById('staff-search').addEventListener('input', () => this.renderStaffPage());

        // Hire
        const hireBtn = document.createElement('button');
        hireBtn.className = 'btn btn-primary';
        hireBtn.innerHTML = '<i class="fas fa-user-plus"></i> Contratar';
        hireBtn.addEventListener('click', () => {
            document.getElementById('hire-passport').value = '';
            this.openModal('modal-hire');
        });

        const headerActions = document.querySelector('#page-funcionarios .header-actions');
        if (headerActions && !headerActions.querySelector('.btn-primary')) {
            headerActions.appendChild(hireBtn);
        }

        document.getElementById('btn-confirm-hire').addEventListener('click', () => {
            const passport = document.getElementById('hire-passport').value.trim();
            if (!passport) return;
            fetch('https://Painel_Mecanica/hireMedic', { method: 'POST', body: JSON.stringify({ passport: passport }) });
            this.closeModal('modal-hire');
            setTimeout(() => {
                fetch('https://Painel_Mecanica/refreshData', { method: 'POST', body: JSON.stringify({}) });
            }, 600);
        });

        document.getElementById('btn-fire-staff').addEventListener('click', () => {
            const passport = document.getElementById('manage-staff-passport').textContent;
            if (!passport) return;
            fetch('https://Painel_Mecanica/fireMedic', { method: 'POST', body: JSON.stringify({ passport: passport }) });
            this.closeModal('modal-staff');
            setTimeout(() => {
                fetch('https://Painel_Mecanica/refreshData', { method: 'POST', body: JSON.stringify({}) });
            }, 600);
        });

        document.getElementById('btn-save-staff').addEventListener('click', () => {
            const passport = document.getElementById('manage-staff-passport').textContent;
            const level = document.getElementById('manage-staff-level').value;
            if (!passport || !level) return;
            fetch('https://Painel_Mecanica/setMedicLevel', {
                method: 'POST',
                body: JSON.stringify({ passport: parseInt(passport), level: parseInt(level) })
            });
            this.closeModal('modal-staff');
            setTimeout(() => {
                fetch('https://Painel_Mecanica/refreshData', { method: 'POST', body: JSON.stringify({}) });
            }, 600);
        });
    },

    renderStaffPage() {
        if (!this.data || !this.data.medics) return;

        const search = document.getElementById('staff-search').value.toLowerCase();
        let medics = this.data.medics;

        if (search) {
            medics = medics.filter(m =>
                (m.name || '').toLowerCase().includes(search) ||
                String(m.passport).includes(search) ||
                (m.role || '').toLowerCase().includes(search)
            );
        }

        const tbody = document.getElementById('staff-tbody');
        const myLevel = this.data.myLevel;
        const canManage = this.hasPermission('manage_staff');

        if (medics.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;color:var(--text-muted);padding:30px">Nenhum funcionário encontrado</td></tr>';
            return;
        }

        tbody.innerHTML = medics.map(m => `
            <tr>
                <td>${m.passport}</td>
                <td>${this.esc(m.name)}</td>
                <td>${this.esc(m.role)}</td>
                <td><span class="status-dot ${m.online ? 'online' : 'offline'}"></span>${m.online ? 'Online' : 'Offline'}</td>
                <td>${m.lastlogin_formatted || 'Nunca'}</td>
                <td>
                    ${canManage && m.passport !== this.data.myPassport && (m.level > myLevel || myLevel === 0) ? `
                        <button class="table-action manage" title="Gerenciar" onclick="App.openStaffManage(${m.passport}, '${this.esc(m.name)}', ${m.level})"><i class="fas fa-cog"></i></button>
                    ` : ''}
                </td>
            </tr>
        `).join('');
    },

    openStaffManage(passport, name, level) {
        document.getElementById('manage-staff-name').textContent = name;
        document.getElementById('manage-staff-passport').textContent = passport;
        document.getElementById('manage-staff-rank').textContent = this.getRoleLabel(level);

        // Populate level select
        const sel = document.getElementById('manage-staff-level');
        sel.innerHTML = '';
        const roles = this.data.roles || {};
        const myLevel = this.data.myLevel;

        const maxRoleLevel = Object.keys(roles).length > 0 ? Math.max(...Object.keys(roles).map(Number)) : 5;

        for (let i = Math.max(1, myLevel); i <= maxRoleLevel; i++) {
            if (!roles[i] && !roles[String(i)]) continue;
            const opt = document.createElement('option');
            opt.value = i;
            opt.textContent = `${i} - ${roles[i] || roles[String(i)]}`;
            if (i === level) opt.selected = true;
            sel.appendChild(opt);
        }

        // Show/hide fire based on permission
        const fireBtn = document.getElementById('btn-fire-staff');
        fireBtn.style.display = this.hasPermission('fire') ? 'inline-flex' : 'none';

        this.openModal('modal-staff');
    },

    // ========== MODALS ==========
    bindModals() {
        document.querySelectorAll('.modal-close, .modal-cancel').forEach(btn => {
            btn.addEventListener('click', () => {
                const modal = btn.closest('.modal');
                if (modal) this.closeModal(modal.id);
            });
        });

        document.querySelectorAll('.modal-overlay').forEach(overlay => {
            overlay.addEventListener('click', () => {
                const modal = overlay.closest('.modal');
                if (modal) this.closeModal(modal.id);
            });
        });
    },

    openModal(id) {
        document.getElementById(id)?.classList.remove('hidden');
    },

    closeModal(id) {
        document.getElementById(id)?.classList.add('hidden');
    },

    // ========== UTILITIES ==========
    esc(str) {
        if (!str) return '';
        const div = document.createElement('div');
        div.appendChild(document.createTextNode(String(str)));
        return div.innerHTML;
    },

    truncate(str, max) {
        if (!str) return '';
        str = String(str);
        return str.length > max ? str.substring(0, max) + '...' : str;
    },

    formatDate(dateStr) {
        if (!dateStr) return '-';
        try {
            const d = new Date(dateStr);
            if (isNaN(d.getTime())) return String(dateStr);
            const day = String(d.getDate()).padStart(2, '0');
            const month = String(d.getMonth() + 1).padStart(2, '0');
            const year = d.getFullYear();
            const hours = String(d.getHours()).padStart(2, '0');
            const mins = String(d.getMinutes()).padStart(2, '0');
            return `${day}/${month}/${year} ${hours}:${mins}`;
        } catch (e) {
            return String(dateStr);
        }
    },

    statusBadge(status) {
        const map = {
            'Em peças instaladas': 'blue',
            'Concluído': 'green',
            'Cancelada': 'red',
            'Cancelado': 'red',
            'Agendada': 'blue',
            'Realizada': 'green',
            'Pendente': 'orange',
            'Em andamento': 'blue',
        };
        const color = map[status] || 'blue';
        return `<span class="status-badge ${color}">${this.esc(status)}</span>`;
    },

    getRoleLabel(level) {
        if (!this.data || !this.data.roles) return 'Desconhecido';
        return this.data.roles[level] || this.data.roles[String(level)] || 'Desconhecido';
    },

    hasPermission(perm) {
        if (!this.data) return false;
        if (this.data.myLevel === 0) return true;
        const maxLevel = this.data.permissions?.[perm];
        if (maxLevel === undefined || maxLevel === null) return false;
        return this.data.myLevel <= maxLevel;
    },
};

// Init
document.addEventListener('DOMContentLoaded', () => App.init());
