---
name: remotion-dev
description: Use when creating or editing videos programmatically with Remotion/React. Activates for: remotion, video, composicao, cena, animacao, transicao, player video.
chain: none
---

# Remotion Dev - Video Creation Specialist

Especialista em criacao de videos programaticos usando Remotion + React + TypeScript.

## When to Use
- Criar videos de treinamento, tutoriais, demos
- Compor cenas com timing preciso (frame-level)
- Adicionar transicoes entre cenas (fade, slide, wipe, flip)
- Animar elementos (texto, imagens, overlays)
- Embeddar player de video na aplicacao React
- Gerar videos a partir de dados/templates
- NOT when: editar video manualmente, apenas legendas (usar remotion-captions)

## Instructions

### STEP 1: Entender o Projeto
Antes de qualquer codigo, verificar:
1. Se ja existe projeto Remotion (`remotion.config.ts` ou `package.json` com `remotion`)
2. Se nao existe, sugerir inicializacao com template adequado
3. Verificar versao do Remotion instalada

### STEP 2: Estrutura de Composicao

Seguir padrao de composicao Remotion:

```
src/
  compositions/
    TrainingVideo/
      index.tsx          # Composicao principal
      scenes/
        Intro.tsx        # Cena de abertura
        Content.tsx      # Conteudo principal
        CodeDemo.tsx     # Demo de codigo (se aplicavel)
        Summary.tsx      # Resumo/encerramento
      components/
        AnimatedText.tsx # Texto animado reutilizavel
        Overlay.tsx      # Overlays (lower-thirds, titulos)
        Background.tsx   # Backgrounds animados
      styles.ts          # Estilos compartilhados
      schema.ts          # Zod schema para props da composicao
  Root.tsx               # Registro de composicoes
```

### STEP 3: Padrao de Composicao

```tsx
import { Composition } from 'remotion';
import { z } from 'zod';

// Schema de props com Zod
const TrainingVideoSchema = z.object({
  title: z.string(),
  sections: z.array(z.object({
    title: z.string(),
    content: z.string(),
    durationInSeconds: z.number(),
  })),
});

// Registrar composicao em Root.tsx
<Composition
  id="TrainingVideo"
  component={TrainingVideo}
  durationInFrames={fps * totalSeconds}
  fps={30}
  width={1920}
  height={1080}
  schema={TrainingVideoSchema}
  defaultProps={{
    title: "Treinamento",
    sections: [],
  }}
/>
```

### STEP 4: Cenas com Sequence

```tsx
import { AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig } from 'remotion';

export const TrainingVideo: React.FC<Props> = ({ title, sections }) => {
  const { fps } = useVideoConfig();
  let currentFrame = 0;

  return (
    <AbsoluteFill>
      {/* Intro - 3 segundos */}
      <Sequence from={0} durationInFrames={fps * 3}>
        <Intro title={title} />
      </Sequence>

      {/* Secoes de conteudo */}
      {sections.map((section, i) => {
        const from = fps * 3 + currentFrame;
        const duration = fps * section.durationInSeconds;
        currentFrame += duration;
        return (
          <Sequence key={i} from={from} durationInFrames={duration}>
            <Content {...section} />
          </Sequence>
        );
      })}
    </AbsoluteFill>
  );
};
```

### STEP 5: Animacoes

Usar `interpolate()` e `spring()` para animacoes suaves:

```tsx
import { interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';

const frame = useCurrentFrame();
const { fps } = useVideoConfig();

// Fade in
const opacity = interpolate(frame, [0, 30], [0, 1], {
  extrapolateRight: 'clamp',
});

// Slide in com spring
const translateY = spring({
  frame,
  fps,
  config: { damping: 12, stiffness: 200 },
});

// Scale com easing
const scale = interpolate(frame, [0, 20], [0.8, 1], {
  extrapolateRight: 'clamp',
});
```

### STEP 6: Transicoes

```tsx
import { TransitionSeries, linearTiming } from '@remotion/transitions';
import { fade } from '@remotion/transitions/fade';
import { slide } from '@remotion/transitions/slide';

<TransitionSeries>
  <TransitionSeries.Sequence durationInFrames={90}>
    <SceneA />
  </TransitionSeries.Sequence>
  <TransitionSeries.Transition
    presentation={fade()}
    timing={linearTiming({ durationInFrames: 30 })}
  />
  <TransitionSeries.Sequence durationInFrames={90}>
    <SceneB />
  </TransitionSeries.Sequence>
</TransitionSeries>
```

### STEP 7: Player Embeddable

Para embeddar preview na aplicacao:

```tsx
import { Player } from '@remotion/player';

<Player
  component={TrainingVideo}
  durationInFrames={totalFrames}
  fps={30}
  compositionWidth={1920}
  compositionHeight={1080}
  style={{ width: '100%' }}
  controls
  inputProps={videoProps}
/>
```

### STEP 8: Renderizacao

```bash
# Preview local
npx remotion studio

# Render MP4
npx remotion render TrainingVideo out/video.mp4

# Render com props
npx remotion render TrainingVideo out/video.mp4 --props='{"title":"Meu Treinamento"}'
```

## Key Packages

| Package | Uso |
|---------|-----|
| `remotion` | Core - Composition, Sequence, useCurrentFrame, interpolate, spring |
| `@remotion/transitions` | fade, slide, wipe, flip, clock-wipe |
| `@remotion/player` | Player React embeddable |
| `@remotion/cli` | CLI para render e preview |
| `@remotion/google-fonts` | Google Fonts |
| `@remotion/layout-utils` | Medir texto, fit-to-container |
| `@remotion/shapes` | Formas SVG |
| `@remotion/motion-blur` | Motion blur |
| `@remotion/animation-utils` | CSS animation helpers |
| `@remotion/three` | 3D com React Three Fiber |
| `@remotion/lottie` | Lottie animations |

## Templates Uteis

| Template | Comando |
|----------|---------|
| Hello World | `npx create-video@latest --template hello-world` |
| Code Hike | `npx create-video@latest --template code-hike` |
| TTS Google | `npx create-video@latest --template tts-google` |
| Overlay | `npx create-video@latest --template overlay` |
| Recorder | `npx create-video@latest --template recorder` |

## Common Mistakes
- Nao usar `extrapolateRight: 'clamp'` no interpolate (valores saem do range)
- Esquecer de registrar composicao no Root.tsx
- Nao usar Zod schema para props (quebra o Studio)
- Colocar durationInFrames errado (usar fps * seconds)
- Nao tratar frame 0 (primeira renderizacao)
- Esquecer de instalar `@remotion/bundler` para rendering
- Usar CSS animations ao inves de `interpolate()` (menos controle)
