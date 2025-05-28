# rmGetCodToMD

Este script Bash, `rmGetCodToMD.sh`, está diseñado para facilitar la exportación de múltiples archivos de código fuente desde un directorio de proyecto a un único archivo Markdown bien formateado. Es una herramienta útil para crear documentación, compartir fragmentos de código seleccionados, o para archivar instantáneas de partes específicas de un proyecto.

**Autor:** Ricardo MONLA (rmonla@)
**Versión Actual del Script:** v6.G-ai-Studio.6 (240528 1100 ART)


## Características Principales

*   **Interfaz Interactiva en Terminal:** Ofrece menús claros y navegación basada en la entrada del usuario para una experiencia amigable.
*   **Gestión de Directorio Raíz:** Inicia en el directorio actual pero permite al usuario navegar y seleccionar interactivamente cualquier directorio como la raíz del proyecto para la exportación.
*   **Selector Jerárquico de Archivos/Directorios:**
    *   Muestra la estructura del proyecto en un formato de árbol.
    *   **Archivos:** Pueden ser seleccionados individualmente (`[x]`) para incluir su contenido en el Markdown.
    *   **Directorios:** No son seleccionables para exportación, pero pueden ser expandidos (`[+]`) o colapsados (`[-]`) para visualizar su contenido y facilitar la selección de archivos internos.
*   **Selección Múltiple Avanzada:** Soporta la selección/acción sobre múltiples ítems ingresando números, listas separadas por comas o espacios, y rangos (ej: "1, 3-5, 8").
*   **Generación de Árbol de Directorios:** Crea automáticamente un árbol de texto en el Markdown que representa la estructura de los directorios padres de los archivos seleccionados, ayudando a contextualizar el código.
*   **Resaltado de Sintaxis Automático:** Detecta las extensiones de los archivos seleccionados y las mapea a los identificadores de lenguaje correctos para los bloques de código en Markdown (ej., `*.py` se convierte en ` ```python `).
*   **Nombre de Salida Personalizable:** Solicita al usuario un nombre para el archivo Markdown de salida, sugiriendo un nombre por defecto (ej: `project_NOMBRE-RAIZ_FECHA.md`).
*   **Creación Automática de Directorios de Salida:** Si la ruta de salida especificada incluye directorios que no existen, el script intentará crearlos.
*   **Actualización Automática:** Incluye una opción para descargar y aplicar la última versión del script directamente desde GitHub, con creación de backup previo.
*   **Ayuda Integrada:** Opción de línea de comandos para mostrar información detallada sobre el uso y los comandos.

## Uso

### Opciones de Línea de Comandos

El script `rmGetCodToMD.sh` puede ser invocado con las siguientes opciones:

*   `./rmGetCodToMD.sh -h` o `./rmGetCodToMD.sh --help` (forma larga para documentación)
    Muestra un mensaje de ayuda detallado describiendo el uso del script, las opciones del menú interactivo, y las opciones de línea de comando, luego sale.

*   `./rmGetCodToMD.sh -r` o `./rmGetCodToMD.sh --update` (forma larga para documentación)
    Intenta actualizar el script a su última versión disponible en el repositorio de GitHub. Se solicitará confirmación antes de realizar la actualización. El script saldrá después del intento.

### Funcionamiento Interactivo

Si se ejecuta el script sin opciones de línea de comando que terminen su ejecución (como `-h` o `-r`):

1.  **Navega al directorio raíz de tu proyecto (si es necesario):**
    Aunque puedes cambiar el directorio raíz dentro del script, es conveniente estar en el directorio del proyecto o uno cercano al iniciar.
    ```bash
    cd /ruta/a/tu/proyecto
    ```
2.  **Ejecuta el script:**
    ```bash
    /ruta/al/script/rmGetCodToMD.sh
    ```
    (Si el script está en tu `PATH` o es ejecutable y estás en su directorio: `./rmGetCodToMD.sh`)

3.  **Menú Principal:**
    Se te presentará un menú con las siguientes opciones:
    *   **1) Seleccionar archivos/carpetas:** Abre el selector jerárquico.
    *   **2) Cambiar directorio raíz:** Permite navegar y elegir un nuevo directorio base para el proyecto.
    *   **3) Exportar a Markdown:** Inicia el proceso de generación del archivo Markdown con los archivos actualmente seleccionados.
    *   **4) Actualizar script:** Similar a la opción `-r`.
    *   **5) Salir:** Termina el script.

4.  **Selector de Archivos/Carpetas:**
    *   Navega visualmente la estructura. Los archivos pueden ser seleccionados/deseleccionados. Los directorios pueden ser expandidos/colapsados.
    *   **Entrada Numérica:** Para interactuar con los ítems listados (ej., archivos o directorios), ingresa sus números correspondientes.
        *   **Archivos:** Alterna su estado de selección (`[ ]` <-> `[x]`).
        *   **Directorios:** Alterna su estado de expansión (`[+]` <-> `[-]`).
        *   **Formatos aceptados:**
            *   Un solo número: `5`
            *   Múltiples números separados por coma o espacio: `1,3,5` o `1 3 5`
            *   Rangos: `2-6`
            *   Combinaciones: `1, 3-5, 8`
    *   **Otros comandos disponibles en el selector:**
        *   `a`: Seleccionar todos los **archivos** visibles.
        *   `n`: Deseleccionar todos los **archivos**.
        *   `e`: Expandir todos los directorios.
        *   `c`: Colapsar todos los directorios.
        *   `f`: Finalizar la selección y volver al menú principal.
        *   `q`: Cancelar y volver al menú principal sin guardar cambios en la selección.

5.  **Exportación:**
    *   Tras elegir "Exportar a Markdown", se te pedirá un nombre para el archivo de salida. Se sugiere un nombre por defecto, pero puedes especificar uno diferente, incluyendo una ruta relativa o absoluta.
    *   El script generará el archivo Markdown.

## ¡Apoya este proyecto! ☕
Si encuentras útil este script y la documentación, ¡considera invitarme un café para apoyar mi trabajo!

[![Invítame un café](https://img.shields.io/badge/Invítame_un_café-%23FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=white)](https://bit.ly/4hcukTf)