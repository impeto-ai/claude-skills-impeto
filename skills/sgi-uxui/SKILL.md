---
name: sgi-uxui
description: Especialista UX/UI para SGI usando Bootstrap 5.3 + SCSS. Micro-interações, animações suaves, dark mode, dashboard patterns. Ativa para "uxui", "interface", "animacao", "hover", "transicao", "dark mode".
chain: none
---

# SGI-UXUI - Especialista em Experiência Visual

**Stack:** Bootstrap 5.3.2 + SCSS + Vite + CSS Custom Properties

## Mentalidade UX/UI

```
INTERFACES DEVEM SER:
✦ Responsivas e fluidas
✦ Com micro-interações que guiam o usuário
✦ Acessíveis (a11y) e com reduced-motion
✦ Consistentes com o design system existente
✦ Performáticas (transforms > properties)
```

---

## FRAMEWORK: Bootstrap 5.3 + SCSS

### Capacidades Nativas

| Feature | Suporte | Como Usar |
|---------|---------|-----------|
| Dark Mode | ✅ Nativo | `data-bs-theme="dark"` |
| CSS Variables | ✅ Completo | `var(--bs-primary)` |
| Color Modes | ✅ Múltiplos | `@include color-mode()` |
| Transitions | ✅ Básico | `.fade`, `.collapse` |
| Spinners | ✅ Nativo | `.spinner-border`, `.spinner-grow` |
| Tooltips/Popovers | ✅ JS | `bootstrap.Tooltip` |

### Limitações a Contornar

| Limitação | Solução SGI |
|-----------|-------------|
| Animações limitadas | `_animations.scss` customizado |
| Sem micro-interações | Mixins + keyframes próprios |
| Hover básico | `@mixin smooth-hover` |
| Loading states | Skeleton screens customizados |

---

## DESIGN SYSTEM SGI

### Paleta de Cores

```scss
// Primárias (usar variáveis CSS)
--primary-color: #012044;      // Navy blue
--accent-color: #5BA3D0;       // Light blue
--bs-primary: #012044;

// Semânticas
--bs-success: #2E7D32;
--bs-danger: #f44336;
--bs-warning: #ff9800;
--bs-info: #083368;

// Ratings (Dashboard)
$rating-a: #22c55e;  // Verde - Excelente
$rating-b: #3b82f6;  // Azul - Bom
$rating-c: #f59e0b;  // Amarelo - Regular
$rating-d: #ef4444;  // Vermelho - Ruim
```

### Variáveis CSS Disponíveis

```scss
// Backgrounds
var(--my-card-bg)
var(--bs-body-bg)
var(--bs-tertiary-bg)

// Borders
var(--border-color-subtle)
var(--bs-border-color)
var(--bs-border-radius)  // 8px

// Text
var(--text-primary)
var(--text-secondary)
var(--text-contrast)
var(--bs-body-color)

// Icons
var(--icon-color)
var(--icon-color-rgb)  // Para rgba()
```

### Tipografia

```scss
$font-family-base: 'Nunito', sans-serif;
$font-weight-bold: 700;

// Tamanhos recomendados
h1: 2rem
h2: 1.75rem
h3: 1.5rem
body: 1rem
small: 0.875rem
caption: 0.75rem
```

---

## ANIMAÇÕES EXISTENTES

### Keyframes Disponíveis (`_animations.scss`)

```scss
// Fade In (entrada suave)
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}

// Slide Up (entrada de baixo)
@keyframes slideUp {
  from { opacity: 0; transform: translateY(30px); }
  to { opacity: 1; transform: translateY(0); }
}

// Ripple (efeito material em botões)
@keyframes ripple { ... }

// Spin (loading)
@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

// Pulse (destaque)
@keyframes pulse {
  0% { transform: scale(1); }
  50% { transform: scale(1.05); }
  100% { transform: scale(1); }
}
```

### Mixins Disponíveis (`_mixins.scss`)

```scss
// Hover suave
@mixin smooth-hover($property: all, $duration: 0.2s) {
  transition: $property $duration ease;
  &:hover { @content; }
}

// Flexbox centralizado
@mixin flex-center($direction: row) {
  display: flex;
  flex-direction: $direction;
  align-items: center;
  justify-content: center;
}

// Truncar texto
@mixin truncate-text($lines: 1) { ... }

// Breakpoints
@mixin respond-to($breakpoint) { ... }
// 'mobile': max-width: 767px
// 'tablet': 768px - 991px
// 'desktop': min-width: 992px
```

---

## MICRO-INTERAÇÕES - PATTERNS

### 1. Hover em Cards

```scss
.my-card {
  transition: all 0.2s ease-in-out;

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 25px rgba(0, 0, 0, 0.08);
  }

  // Barra de destaque animada
  &::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 3px;
    background: linear-gradient(90deg, var(--primary-color), var(--accent-color));
    opacity: 0;
    transition: opacity 0.2s ease-in-out;
  }

  &:hover::before {
    opacity: 1;
  }
}
```

### 2. Hover em Ícones

```scss
.icon-interactive {
  transition: all 0.2s ease-in-out;
  opacity: 0.6;

  &:hover {
    opacity: 1;
    transform: scale(1.1);
    color: var(--bs-primary);
  }
}
```

### 3. Feedback em Botões

```scss
.btn-interactive {
  position: relative;
  overflow: hidden;
  transition: all 0.15s ease;

  &:hover {
    filter: brightness(0.95);
    transform: translateY(-1px);
  }

  &:active {
    transform: translateY(0);
    filter: brightness(0.9);
  }

  // Ripple effect opcional
  &::after {
    content: '';
    position: absolute;
    inset: 0;
    background: radial-gradient(circle, rgba(255,255,255,0.3) 0%, transparent 70%);
    opacity: 0;
    transform: scale(0);
    transition: all 0.3s ease;
  }

  &:active::after {
    opacity: 1;
    transform: scale(2);
  }
}
```

### 4. Loading States

```scss
// Skeleton loading
.skeleton {
  background: linear-gradient(
    90deg,
    var(--bs-tertiary-bg) 25%,
    var(--bs-body-bg) 50%,
    var(--bs-tertiary-bg) 75%
  );
  background-size: 200% 100%;
  animation: skeleton-loading 1.5s ease-in-out infinite;
  border-radius: var(--bs-border-radius);
}

@keyframes skeleton-loading {
  0% { background-position: 200% 0; }
  100% { background-position: -200% 0; }
}

// Spinner overlay
.loading-overlay {
  position: absolute;
  inset: 0;
  background: rgba(var(--bs-body-bg-rgb), 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  visibility: hidden;
  transition: all 0.2s ease;

  &.active {
    opacity: 1;
    visibility: visible;
  }
}
```

### 5. Entrada Staggered (lista de itens)

```scss
.staggered-list {
  .list-item {
    opacity: 0;
    animation: slideUp 0.3s ease forwards;

    @for $i from 1 through 10 {
      &:nth-child(#{$i}) {
        animation-delay: #{$i * 0.05}s;
      }
    }
  }
}
```

### 6. Accordion Suave

```scss
.accordion-smooth {
  .accordion-collapse {
    transition: height 0.3s ease;
  }

  .accordion-button {
    transition: all 0.2s ease;

    &:not(.collapsed) {
      background: rgba(var(--bs-primary-rgb), 0.05);
    }

    &::after {
      transition: transform 0.3s ease;
    }
  }
}
```

---

## DARK MODE - IMPLEMENTAÇÃO

### Usando color-mode() Mixin

```scss
@include color-mode(dark) {
  .my-component {
    background: var(--my-card-bg);
    border-color: var(--border-color-subtle);

    &:hover {
      box-shadow: 0 8px 25px rgba(0, 0, 0, 0.25);
    }
  }
}
```

### Ou Seletor Direto

```scss
[data-bs-theme="dark"] {
  .my-component {
    // estilos dark mode
  }
}
```

### Cores Adaptativas

```scss
// Usar variáveis que já se adaptam
.adaptive-card {
  background: var(--my-card-bg);        // auto-adapta
  color: var(--bs-body-color);          // auto-adapta
  border-color: var(--bs-border-color); // auto-adapta
}

// Cores semânticas com transparência
.status-success {
  background: rgba(var(--bs-success-rgb), 0.15);
  color: var(--bs-success-text-emphasis);
  border-left: 3px solid var(--bs-success);
}
```

---

## DASHBOARD PATTERNS

### Layout de KPIs (Padrão SGI)

```html
<!-- Desktop: Grid responsivo -->
<div class="row g-3 mb-4">
  <div class="col-md-6 col-lg-3">
    <div class="kpi-card kpi-card--success">...</div>
  </div>
</div>

<!-- Mobile: Scroll horizontal -->
<div class="kpi-cards-scroll-wrapper d-md-none">
  <div class="kpi-cards-scroll">
    <div class="kpi-card-mobile">...</div>
  </div>
</div>
```

### Hierarquia Visual (F-Pattern)

```
┌─────────────────────────────────────┐
│  KPI 1 (crítico)  │  KPI 2  │  KPI 3  │  KPI 4  │
├─────────────────────────────────────┤
│                                     │
│  Gráfico Principal                  │  Filtros
│  (área maior)                       │  (sidebar)
│                                     │
├─────────────────────────────────────┤
│  Tabela / Lista de Detalhes         │
└─────────────────────────────────────┘
```

### Cards Bento Grid

```scss
.bento-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1rem;

  .bento-item {
    background: var(--my-card-bg);
    border-radius: var(--bs-border-radius-lg);
    padding: 1.5rem;

    &--featured {
      grid-column: span 2;
      grid-row: span 2;
    }

    &--wide {
      grid-column: span 2;
    }

    &--tall {
      grid-row: span 2;
    }
  }

  @include respond-to('tablet') {
    grid-template-columns: repeat(2, 1fr);
  }

  @include respond-to('mobile') {
    grid-template-columns: 1fr;

    .bento-item--featured,
    .bento-item--wide {
      grid-column: span 1;
    }
  }
}
```

---

## ACESSIBILIDADE (a11y)

### Reduced Motion

```scss
@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

### Focus Visible

```scss
.interactive-element {
  &:focus-visible {
    outline: 2px solid var(--bs-primary);
    outline-offset: 2px;
  }

  &:focus:not(:focus-visible) {
    outline: none;
  }
}
```

### Contraste

```scss
// Sempre testar contraste de texto
// Usar variáveis de emphasis para texto sobre cores
.badge-status {
  background: rgba(var(--bs-success-rgb), 0.15);
  color: var(--bs-success-text-emphasis); // garante contraste
}
```

---

## TIMING & EASING - BOAS PRÁTICAS

### Duração Recomendada

| Tipo | Duração | Uso |
|------|---------|-----|
| Micro (hover) | 0.1s - 0.2s | Botões, ícones |
| Pequena | 0.2s - 0.3s | Cards, dropdowns |
| Média | 0.3s - 0.4s | Modais, accordions |
| Grande | 0.4s - 0.5s | Page transitions |

### Easing Functions

```scss
// Suave padrão
$ease-smooth: ease-in-out;

// Entrada rápida, saída suave
$ease-out: cubic-bezier(0.25, 0.46, 0.45, 0.94);

// Bounce suave
$ease-bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55);

// Entrada suave
$ease-in: cubic-bezier(0.55, 0.055, 0.675, 0.19);
```

### Performance

```scss
// PREFIRA (GPU accelerated)
transform: translateX() / translateY() / scale() / rotate()
opacity

// EVITE (causa repaint)
width, height, top, left, margin, padding
```

---

## COMPONENTES EXISTENTES - REFERÊNCIA

### KPI Cards (`_kpi-cards.scss`)
- `.kpi-card` - Card base com hover lift
- `.kpi-card--success/warning/danger/info` - Variantes
- `.kpi-cards-scroll` - Scroll horizontal mobile
- Suporta dark mode nativo

### Filter Pills (`_filter-pills.scss`)
- `.filter-pills` - Container de filtros
- `.filter-pill` - Pill individual
- `.filter-pill--active` - Estado ativo
- `.filter-pill--warning/success` - Variantes semânticas

### Calendário (`_calendario.scss`)
- `.calendario-day` - Dia com hover
- `.calendario-event` - Evento com status color
- `.rotina-popup` - Popup hover com fade

### Cards Onboarding (`sgi-onboarding-card`)
- `.sgi-onboarding-card--static` - Card base sem animação
- Usado em layouts de formulário

---

## CHECKLIST UX/UI

### Antes de Implementar

```
[ ] A animação tem propósito (guia, confirma, orienta)?
[ ] Duração está entre 0.1s - 0.5s?
[ ] Usa transform/opacity (não width/height)?
[ ] Funciona com prefers-reduced-motion?
[ ] Mantém contraste em dark mode?
[ ] Tem estado :focus-visible?
```

### Depois de Implementar

```
[ ] Testei em mobile (touch)?
[ ] Testei em dark mode?
[ ] Animação não causa layout shift?
[ ] Performance OK (60fps)?
[ ] Consistente com outros componentes?
```

---

## EXEMPLOS PRÁTICOS

### Card com Todos os Patterns

```scss
.enhanced-card {
  // Base
  background: var(--my-card-bg);
  border: 1px solid var(--bs-border-color);
  border-radius: var(--bs-border-radius-lg);
  transition: all 0.2s ease-in-out;
  position: relative;
  overflow: hidden;

  // Accent bar
  &::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 3px;
    background: linear-gradient(90deg, var(--bs-primary), var(--accent-color));
    opacity: 0;
    transition: opacity 0.2s ease;
  }

  // Hover state
  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.1);

    &::before {
      opacity: 1;
    }

    .enhanced-card__icon {
      transform: scale(1.1);
      opacity: 1;
    }
  }

  // Focus state (a11y)
  &:focus-visible {
    outline: 2px solid var(--bs-primary);
    outline-offset: 2px;
  }

  // Icon
  &__icon {
    transition: all 0.2s ease;
    opacity: 0.6;
  }

  // Dark mode
  [data-bs-theme="dark"] & {
    &:hover {
      box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
    }
  }

  // Reduced motion
  @media (prefers-reduced-motion: reduce) {
    transition: none;

    &:hover {
      transform: none;
    }

    &::before {
      transition: none;
    }
  }
}
```

---

## FONTES & REFERÊNCIAS

- [Bootstrap 5.3 Color Modes](https://getbootstrap.com/docs/5.3/customize/color-modes/)
- [Bootstrap 5.3 CSS Variables](https://getbootstrap.com/docs/5.3/customize/css-variables/)
- [Bootstrap 5.3 Sass Customization](https://getbootstrap.com/docs/5.3/customize/sass/)
- [Dashboard Design Principles 2026](https://www.designrush.com/agency/ui-ux-design/dashboard/trends/dashboard-design-principles)
- [Micro-Interactions & Motion 2026](https://primotech.com/ui-ux-evolution-2026-why-micro-interactions-and-motion-matter-more-than-ever/)
- [MDB Bootstrap Animations](https://mdbootstrap.com/docs/standard/content-styles/animations/)
- [MDB Hover Effects](https://mdbootstrap.com/docs/standard/content-styles/hover-effects/)
