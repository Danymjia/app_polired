import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import 'help_detail_screen.dart';

class FAQData {
  final String title;
  final String introduction;
  final List<String> steps;
  final String note;

  const FAQData({
    required this.title,
    required this.introduction,
    required this.steps,
    required this.note,
  });
}

/// Responsabilidad principal:
/// Pantalla principal del centro de ayuda, lista de Preguntas Frecuentes (FAQs) estáticas.
///
/// Flujo dentro de la app:
/// Accesible desde `SettingsScreen` en la sección "Soporte y recursos".
///
/// Dependencias críticas:
/// - Navega a `HelpDetailScreen` para mostrar el detalle de cada FAQ.
///
/// Side Effects:
/// - Ninguno.
///
/// Recordatorios técnicos y CQRS:
/// - Las preguntas y respuestas están hardcodeadas en memoria (`_faqs`). Si en el futuro deben ser dinámicas, se requerirá conectarlo a un provider/servicio.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const List<FAQData> _faqs = [
    FAQData(
      title: '¿Cómo puedo unirme a una nueva red?',
      introduction: 'Unirse a una red te permite interactuar con contenidos académicos, enterarte de eventos de tu facultad y colaborar con otros compañeros.',
      steps: [
        'Dirígete a la sección de **Explorar** utilizando la barra de navegación o el buscador de la aplicación.',
        'Usa el buscador o explora el catálogo para encontrar la red de tu facultad o área académica.',
        'Haz clic en la red que deseas unirte para ver su información y publicaciones públicas.',
        'Presiona el botón azul **\'Unirse\'** en la parte superior para ingresar como miembro activo.'
      ],
      note: 'Al unirte, podrás interactuar con los contenidos, publicar nuevas entradas, dar me gusta y comentar en el feed oficial.',
    ),
    FAQData(
      title: '¿Cómo cambio mi foto de perfil?',
      introduction: 'Tu foto de perfil ayuda a que los docentes y compañeros te identifiquen fácilmente dentro del entorno académico de Polired.',
      steps: [
        'Ve a tu **Perfil** desde la esquina inferior derecha de la pantalla principal.',
        'Presiona el botón **\'Editar Perfil\'** ubicado debajo de tu nombre y datos académicos.',
        'Toca el ícono de la cámara sobre tu foto actual para abrir la galería o tomar una nueva foto.',
        'Selecciona tu foto favorita, ajústala y presiona el botón **\'Guardar cambios\'\'.'
      ],
      note: 'Recomendamos usar una foto clara y presentable para mantener el ambiente académico y profesional de la comunidad universitaria.',
    ),
    FAQData(
      title: '¿Cómo puedo denunciar una publicación?',
      introduction: 'Para mantener una convivencia sana y respetuosa en Polired, puedes reportar contenidos inapropiados de forma confidencial.',
      steps: [
        'En la publicación que deseas reportar, toca los **tres puntos (...)** en la esquina superior derecha.',
        'Selecciona la opción **\'Reportar\'** en el menú desplegable.',
        'Elige el **motivo de tu denuncia** de la lista proporcionada. Ofrecemos categorías específicas para agilizar la revisión.',
        'Presiona **\'Enviar reporte\'** para confirmar tu acción.'
      ],
      note: 'Nuestro equipo revisará la publicación para asegurar que cumple con nuestras normas de convivencia universitaria. Tu anonimato está garantizado durante todo el proceso.',
    ),
    FAQData(
      title: '¿Cómo recupero mi contraseña?',
      introduction: 'Si olvidaste tu contraseña o tu cuenta está bloqueada, puedes restablecerla de forma segura usando tu correo electrónico.',
      steps: [
        'En la pantalla de inicio de sesión de la aplicación, toca en **\'¿Olvidaste tu contraseña?\'**.',
        'Introduce el **correo institucional** registrado con tu cuenta de Polired.',
        'Busca en tu bandeja de entrada el correo con el enlace de recuperación y el token de verificación.',
        'Ingresa el código en la app, escribe tu **nueva contraseña** segura y confírmala.'
      ],
      note: 'Por motivos de seguridad académica, el enlace expira en 2 horas. Si no lo recibes, verifica tu carpeta de spam o correo no deseado.',
    ),
    FAQData(
      title: '¿Cómo puedo crear mi propia red comunitaria?',
      introduction: 'Cualquier estudiante o docente puede proponer la creación de una red académica, de investigación o de interés estudiantil.',
      steps: [
        'Abre la pantalla de **Configuración** y pulsa en el botón **\'Solicitar apertura de red\'**.',
        'Completa el formulario ingresando un **nombre formal** para la comunidad y una **descripción académica** clara.',
        'Especifica los objetivos de la red y el departamento o facultad al que pertenece.',
        'Presiona **\'Enviar solicitud\'** para que sea evaluada por el equipo de moderadores y superadmins.'
      ],
      note: 'El proceso de aprobación puede tomar hasta 48 horas hábiles. Recibirás una notificación en la aplicación si tu solicitud es aprobada o denegada.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined, size: 20, color: AppTheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ayuda',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.onBackground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: AppTheme.outlineVariant.withValues(alpha: 0.3),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Text(
                'Preguntas Frecuentes',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onBackground,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._faqs.map((faq) => _buildFaqItem(context, faq)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, FAQData faq) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HelpDetailScreen(
              title: faq.title,
              introduction: faq.introduction,
              steps: faq.steps,
              note: faq.note,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.surfaceContainerHigh, width: 1.0),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                faq.title,
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.onBackground,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppTheme.outlineVariant),
          ],
        ),
      ),
    );
  }
}
