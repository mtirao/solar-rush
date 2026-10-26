#!/bin/bash
set -e

echo "🛸 Validando dependencias para Solar Rush..."

# 1. Comprobar si Homebrew está instalado para obtener XcodeGen
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew no está instalado. Instálalo en https://brew.sh antes de continuar."
    exit 1
fi

# 2. Instalar XcodeGen si no se encuentra en el sistema
if ! command -v xcodegen &> /dev/null; then
    echo "📥 Instalando XcodeGen vía Homebrew..."
    brew install xcodegen
else
    echo "✅ XcodeGen ya se encuentra instalado."
fi

# 3. Generar el archivo final .xcodeproj
echo "⚙️ Generando proyecto de Xcode a partir de project.yml..."
xcodegen generate

echo "🎉 ¡Todo listo! Ya puedes abrir SolarRush.xcodeproj y comenzar a programar."
