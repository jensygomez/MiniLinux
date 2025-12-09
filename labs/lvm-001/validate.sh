#!/bin/bash
echo "🔍 VALIDANDO LVM-001..."
if pvs | grep -q loop1; then
    echo "✅ ✓ Physical Volume /dev/loop1 CREADO CORRECTAMENTE!"
    echo "🎉 LABORATORIO COMPLETADO - 20 PUNTOS!"
else
    echo "❌ ✗ No encontrado /dev/loop1 en pvs"
    echo "🔄 Ejecuta: sudo pvcreate /dev/loop1"
fi
