# Mudanças

## v1.1

Foco em self-service: reduzir o número de casos que precisam de ajuda humana.

**Novo**

- `playthrough_diagnostico.lua`: relatório de ambiente que não altera nada no
  projeto. Checa REAPER, ffmpeg, sample rate, e analisa os itens selecionados
- Pasta `Teste/` com dois arquivos de deslocamento conhecido (3 segundos), pra
  validar a instalação sem precisar gravar
- `TO COM PROBLEMA.txt`: roteiro de 4 passos, do mais barato ao mais caro
- Códigos de erro `[PT-xx]` em todas as mensagens, mapeados numa tabela do
  LEIA-ME

**Motivo dos códigos**

"Não funcionou" não é reportável. "Deu PT-03" é. A pessoa procura o código,
acha a causa, e resolve sozinha na maioria das vezes.

**Motivo dos arquivos de teste**

Separa instalação quebrada de gravação errada antes que a pessoa se frustre.
Se o teste dá +3000 ms, a instalação está boa e o problema está no take.

## v1.0

Versão inicial.

- `playthrough_sync_video.lua`: alinha vídeo e áudio pelo transiente
- `playthrough_export_mux.lua`: renderiza e junta sem re-encodar o vídeo
- Template de projeto
- `LEIA-ME.md` e `CONTEXTO-IA.md`
- `INSTALAR.bat`
