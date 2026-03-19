---
name: remotion-captions
description: Use when adding captions, subtitles, or TTS narration to Remotion videos. Activates for: legenda, subtitle, caption, whisper, tts, narration, transcrição.
chain: none
---

# Remotion Captions - Legendas & Narracao

Especialista em legendas automaticas, transcricao com Whisper e narracao TTS para videos Remotion.

## When to Use
- Adicionar legendas/subtitulos a videos
- Transcrever audio com Whisper (OpenAI API, local, ou browser)
- Gerar narracao com TTS (Azure, Google)
- Parsear arquivos SRT
- Criar legendas animadas word-by-word
- Sincronizar audio com legendas
- NOT when: composicao de cenas sem legendas (usar remotion-dev)

## Instructions

### STEP 1: Escolher Abordagem de Legendas

| Abordagem | Quando Usar | Package |
|-----------|-------------|---------|
| Whisper API (OpenAI) | Tem audio, quer transcricao cloud | `@remotion/openai-whisper` |
| Whisper local | Quer transcricao offline/gratuita | `@remotion/install-whisper-cpp` |
| Whisper browser | Transcricao no browser (WASM) | `@remotion/whisper-web` |
| SRT manual | Ja tem arquivo SRT pronto | `@remotion/captions` |
| TTS + Legendas | Quer gerar audio E legendas de texto | `template-tts-google` ou `template-tts-azure` |

### STEP 2: Transcricao com Whisper

#### Via OpenAI API:

```tsx
import { openAiWhisperApiToCaptions } from '@remotion/openai-whisper';

// Chamar API do OpenAI Whisper
const transcription = await openai.audio.transcriptions.create({
  file: audioFile,
  model: 'whisper-1',
  response_format: 'verbose_json',
  timestamp_granularities: ['word'],
});

// Converter para formato Remotion
const { captions } = openAiWhisperApiToCaptions({
  transcription,
});
```

#### Via Whisper Local (whisper.cpp):

```tsx
import { installWhisperCpp, transcribe } from '@remotion/install-whisper-cpp';

// Instalar whisper.cpp
await installWhisperCpp({ version: '1.5.5', to: './whisper' });

// Baixar modelo
await downloadWhisperModel({ folder: './whisper', model: 'medium' });

// Transcrever
const result = await transcribe({
  inputPath: './audio.wav',
  whisperPath: './whisper',
  model: 'medium',
  tokenLevelTimestamps: true,
});
```

#### Via Browser (WASM):

```tsx
import { transcribe } from '@remotion/whisper-web';

const result = await transcribe({
  audioData: float32Array,
  model: 'tiny',
  onProgress: (p) => console.log(`${p}%`),
});
```

### STEP 3: Manipular Captions

```tsx
import {
  parseSrt,
  serializeSrt,
  createTikTokStyleCaptions,
} from '@remotion/captions';

// Parsear SRT
const captions = parseSrt(srtContent);

// Criar legendas estilo TikTok (word-by-word highlight)
const { pages } = createTikTokStyleCaptions({
  captions,
  combineTokensWithinMilliseconds: 800,
});
```

### STEP 4: Renderizar Legendas no Video

#### Legendas Simples:

```tsx
import { useCurrentFrame, useVideoConfig } from 'remotion';

const SubtitleTrack: React.FC<{ captions: Caption[] }> = ({ captions }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const currentTimeMs = (frame / fps) * 1000;

  const currentCaption = captions.find(
    (c) => currentTimeMs >= c.startMs && currentTimeMs < c.endMs
  );

  if (!currentCaption) return null;

  return (
    <div style={{
      position: 'absolute',
      bottom: 80,
      left: 0,
      right: 0,
      textAlign: 'center',
      fontSize: 48,
      fontWeight: 'bold',
      color: 'white',
      textShadow: '2px 2px 8px rgba(0,0,0,0.8)',
      padding: '8px 16px',
    }}>
      {currentCaption.text}
    </div>
  );
};
```

#### Legendas Estilo TikTok (word-by-word):

```tsx
const TikTokCaptions: React.FC<{ pages: CaptionPage[] }> = ({ pages }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const currentTimeMs = (frame / fps) * 1000;

  const currentPage = pages.find(
    (p) => currentTimeMs >= p.startMs && currentTimeMs < p.endMs
  );

  if (!currentPage) return null;

  return (
    <div style={{
      position: 'absolute',
      bottom: 100,
      left: 0,
      right: 0,
      textAlign: 'center',
      display: 'flex',
      flexWrap: 'wrap',
      justifyContent: 'center',
      gap: 8,
    }}>
      {currentPage.tokens.map((token, i) => {
        const isActive = currentTimeMs >= token.fromMs;
        return (
          <span key={i} style={{
            fontSize: 52,
            fontWeight: 'bold',
            color: isActive ? '#FFD700' : 'white',
            textShadow: '2px 2px 8px rgba(0,0,0,0.9)',
            transition: 'color 0.1s',
          }}>
            {token.text}
          </span>
        );
      })}
    </div>
  );
};
```

### STEP 5: TTS (Text-to-Speech) Narracao

#### Google TTS:

```tsx
import { googleTts } from './tts-google';

// Gerar audio de narracao
const audioBuffer = await googleTts({
  text: "Bem-vindo ao treinamento",
  languageCode: "pt-BR",
  voiceName: "pt-BR-Wavenet-A",
});

// Salvar e usar como <Audio> no Remotion
```

#### Azure TTS:

```tsx
import * as sdk from 'microsoft-cognitiveservices-speech-sdk';

const synthesizer = new sdk.SpeechSynthesizer(speechConfig);
const result = await synthesizer.speakTextAsync(text);
```

### STEP 6: Combinar Audio + Legendas

```tsx
import { Audio, Sequence, AbsoluteFill } from 'remotion';

const NarratedScene: React.FC<Props> = ({ audioSrc, captions }) => {
  return (
    <AbsoluteFill>
      {/* Conteudo visual */}
      <Background />
      <ContentSlides />

      {/* Audio de narracao */}
      <Audio src={audioSrc} />

      {/* Legendas sincronizadas */}
      <SubtitleTrack captions={captions} />
    </AbsoluteFill>
  );
};
```

## Key Packages

| Package | Uso |
|---------|-----|
| `@remotion/captions` | Parsear SRT, criar TikTok captions, manipular legendas |
| `@remotion/openai-whisper` | Converter output Whisper API para captions |
| `@remotion/install-whisper-cpp` | Instalar e rodar Whisper localmente |
| `@remotion/whisper-web` | Whisper no browser via WASM |

## Workflow Completo: Audio -> Legendas -> Video

```
1. Gravar/gerar audio (TTS ou gravacao manual)
2. Transcrever com Whisper (API, local, ou browser)
3. Converter transcricao para captions Remotion
4. (Opcional) Editar captions manualmente
5. Renderizar legendas animadas no video
6. Exportar video final com legendas burned-in
```

## Formatos de Caption Suportados

- **SRT** (SubRip) - formato universal
- **Whisper JSON** - output direto da API OpenAI
- **Whisper.cpp** - output do whisper.cpp local
- **Custom JSON** - formato proprio com `{ text, startMs, endMs }`

## Common Mistakes
- Nao usar `timestamp_granularities: ['word']` no Whisper API (perde timing por palavra)
- Esquecer de converter milliseconds para frames ao posicionar legendas
- Nao tratar caracteres especiais no SRT (acentos, emojis)
- Usar fonte sem suporte a PT-BR (acentos quebrados)
- Nao sincronizar duracao do audio com durationInFrames da composicao
- Esquecer de pre-carregar audio com `@remotion/preload` (causa atrasos)
- Nao lidar com gaps entre captions (momentos de silencio)
