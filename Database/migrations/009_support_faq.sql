-- ============================================
-- NAPLET - Support & FAQ Tables
-- Migration: 009_support_faq.sql
-- ============================================

-- ============================================
-- 1. FAQ ITEMS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.faq_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category TEXT NOT NULL, -- 'general', 'sleep', 'subscription', 'technical', 'account'
    question_pt TEXT NOT NULL,
    question_en TEXT NOT NULL,
    question_es TEXT NOT NULL,
    answer_pt TEXT NOT NULL,
    answer_en TEXT NOT NULL,
    answer_es TEXT NOT NULL,
    order_index INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Index for ordering
CREATE INDEX IF NOT EXISTS idx_faq_category_order ON public.faq_items(category, order_index);

-- Enable RLS
ALTER TABLE public.faq_items ENABLE ROW LEVEL SECURITY;

-- Policy: anyone can read active FAQ items
DROP POLICY IF EXISTS "Anyone can read FAQ" ON public.faq_items;
CREATE POLICY "Anyone can read FAQ" ON public.faq_items
    FOR SELECT USING (is_active = true);

-- ============================================
-- 2. SUPPORT TICKETS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.support_tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    user_email TEXT NOT NULL,
    user_name TEXT,
    category TEXT NOT NULL, -- 'bug', 'feature', 'billing', 'question', 'other'
    subject TEXT NOT NULL,
    message TEXT NOT NULL,
    app_version TEXT,
    device_info TEXT,
    status TEXT DEFAULT 'open', -- 'open', 'in_progress', 'resolved', 'closed'
    created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT now() NOT NULL
);

-- Index for user tickets
CREATE INDEX IF NOT EXISTS idx_support_tickets_user ON public.support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON public.support_tickets(status);

-- Enable RLS
ALTER TABLE public.support_tickets ENABLE ROW LEVEL SECURITY;

-- Policy: anyone can create tickets (even anonymous)
DROP POLICY IF EXISTS "Anyone can create tickets" ON public.support_tickets;
CREATE POLICY "Anyone can create tickets" ON public.support_tickets
    FOR INSERT WITH CHECK (true);

-- Policy: users can view their own tickets
DROP POLICY IF EXISTS "Users can view own tickets" ON public.support_tickets;
CREATE POLICY "Users can view own tickets" ON public.support_tickets
    FOR SELECT USING (auth.uid() = user_id);

-- ============================================
-- 3. SEED FAQ DATA
-- ============================================

-- Clear existing FAQ items (optional - remove if you want to keep existing)
-- DELETE FROM public.faq_items;

-- Insert FAQ items
INSERT INTO public.faq_items (category, question_pt, question_en, question_es, answer_pt, answer_en, answer_es, order_index) VALUES

-- GENERAL
('general',
 'O que é o Naplet?',
 'What is Naplet?',
 '¿Qué es Naplet?',
 'O Naplet é um aplicativo completo para acompanhar o sono e a rotina do seu bebê. Com ele, você pode registrar sonecas, alimentação, fraldas e muito mais. Além disso, oferecemos um assistente de IA para tirar suas dúvidas sobre o sono do bebê.',
 'Naplet is a complete app to track your baby''s sleep and routine. With it, you can log naps, feedings, diapers and much more. We also offer an AI assistant to answer your questions about baby sleep.',
 'Naplet es una aplicación completa para seguir el sueño y la rutina de tu bebé. Con ella, puedes registrar siestas, alimentación, pañales y mucho más. Además, ofrecemos un asistente de IA para responder tus preguntas sobre el sueño del bebé.',
 1),

('general',
 'O Naplet é gratuito?',
 'Is Naplet free?',
 '¿Naplet es gratis?',
 'O Naplet oferece um plano gratuito com funcionalidades básicas. Para desbloquear recursos avançados como Chat IA ilimitado, relatórios para pediatra e convite de cuidadores, você pode assinar o Naplet Premium.',
 'Naplet offers a free plan with basic features. To unlock advanced features like unlimited AI Chat, pediatrician reports, and caregiver invites, you can subscribe to Naplet Premium.',
 'Naplet ofrece un plan gratuito con funcionalidades básicas. Para desbloquear recursos avanzados como Chat IA ilimitado, informes para pediatra e invitación de cuidadores, puedes suscribirte a Naplet Premium.',
 2),

('general',
 'Como convido meu parceiro(a) ou avós?',
 'How do I invite my partner or grandparents?',
 '¿Cómo invito a mi pareja o abuelos?',
 'No plano Premium, você pode convidar cuidadores ilimitados. Vá em Configurações > Convidar Cuidador e envie o código de convite por WhatsApp, SMS ou email. A pessoa convidada baixa o app e insere o código para ter acesso aos dados do bebê em tempo real.',
 'With the Premium plan, you can invite unlimited caregivers. Go to Settings > Invite Caregiver and send the invite code via WhatsApp, SMS or email. The invited person downloads the app and enters the code to access the baby''s data in real-time.',
 'Con el plan Premium, puedes invitar cuidadores ilimitados. Ve a Configuración > Invitar Cuidador y envía el código de invitación por WhatsApp, SMS o email. La persona invitada descarga la app e ingresa el código para acceder a los datos del bebé en tiempo real.',
 3),

-- SLEEP
('sleep',
 'O que é janela de sono?',
 'What is a sleep window?',
 '¿Qué es una ventana de sueño?',
 'A janela de sono é o período ideal entre os sonos do bebê. Se você colocar o bebê para dormir dentro dessa janela, ele tende a dormir mais facilmente e ter um sono mais reparador. O Naplet calcula automaticamente com base na idade do seu bebê.',
 'The sleep window is the ideal period between baby''s sleeps. If you put the baby to sleep within this window, they tend to fall asleep more easily and have better quality sleep. Naplet automatically calculates it based on your baby''s age.',
 'La ventana de sueño es el período ideal entre los sueños del bebé. Si pones al bebé a dormir dentro de esta ventana, tiende a dormirse más fácilmente y tener un sueño más reparador. Naplet lo calcula automáticamente según la edad de tu bebé.',
 1),

('sleep',
 'Como registro uma soneca?',
 'How do I log a nap?',
 '¿Cómo registro una siesta?',
 'Na tela inicial, toque em "Iniciar Sono" quando o bebê começar a dormir. Quando acordar, toque em "Parar Sono". Você também pode adicionar detalhes como onde o bebê dormiu e a qualidade do sono. Para registrar sonecas passadas, use o menu Ações Rápidas > Soneca.',
 'On the home screen, tap "Start Sleep" when the baby starts sleeping. When they wake up, tap "Stop Sleep". You can also add details like where the baby slept and sleep quality. To log past naps, use the Quick Actions menu > Nap.',
 'En la pantalla principal, toca "Iniciar Sueño" cuando el bebé empiece a dormir. Cuando despierte, toca "Parar Sueño". También puedes agregar detalles como dónde durmió el bebé y la calidad del sueño. Para registrar siestas pasadas, usa el menú Acciones Rápidas > Siesta.',
 2),

('sleep',
 'O Chat IA pode me ajudar com o sono do bebê?',
 'Can the AI Chat help me with baby sleep?',
 '¿El Chat IA puede ayudarme con el sueño del bebé?',
 'Sim! Nosso assistente de IA foi treinado especificamente para responder dúvidas sobre sono de bebês. Você pode perguntar sobre regressões de sono, transição de sonecas, rotinas e muito mais. No plano gratuito você tem 5 mensagens por mês, no Premium é ilimitado.',
 'Yes! Our AI assistant was specifically trained to answer questions about baby sleep. You can ask about sleep regressions, nap transitions, routines and much more. On the free plan you have 5 messages per month, on Premium it''s unlimited.',
 '¡Sí! Nuestro asistente de IA fue entrenado específicamente para responder dudas sobre el sueño de bebés. Puedes preguntar sobre regresiones de sueño, transición de siestas, rutinas y mucho más. En el plan gratuito tienes 5 mensajes por mes, en Premium es ilimitado.',
 3),

('sleep',
 'Como funciona o modo de sono noturno?',
 'How does night sleep mode work?',
 '¿Cómo funciona el modo de sueño nocturno?',
 'O modo noturno é otimizado para registros durante a madrugada. A tela usa cores mais escuras e menos brilho. Você pode registrar despertares noturnos, mamadas e trocas de fralda sem acordar completamente.',
 'Night mode is optimized for logging during nighttime. The screen uses darker colors and less brightness. You can log night wakings, feedings, and diaper changes without fully waking up.',
 'El modo nocturno está optimizado para registros durante la madrugada. La pantalla usa colores más oscuros y menos brillo. Puedes registrar despertares nocturnos, tomas y cambios de pañal sin despertar completamente.',
 4),

-- SUBSCRIPTION
('subscription',
 'Como funciona o período de teste?',
 'How does the trial period work?',
 '¿Cómo funciona el período de prueba?',
 'Você tem 14 dias para experimentar todos os recursos Premium gratuitamente. Durante esse período, você pode cancelar a qualquer momento sem ser cobrado. Se gostar, a assinatura é renovada automaticamente após o período de teste.',
 'You have 14 days to try all Premium features for free. During this period, you can cancel at any time without being charged. If you like it, the subscription is automatically renewed after the trial period.',
 'Tienes 14 días para probar todas las funciones Premium gratuitamente. Durante este período, puedes cancelar en cualquier momento sin que te cobren. Si te gusta, la suscripción se renueva automáticamente después del período de prueba.',
 1),

('subscription',
 'Como cancelo minha assinatura?',
 'How do I cancel my subscription?',
 '¿Cómo cancelo mi suscripción?',
 'Você pode cancelar sua assinatura a qualquer momento através das Configurações do seu iPhone > Apple ID > Assinaturas > Naplet > Cancelar Assinatura. Você continuará tendo acesso aos recursos Premium até o fim do período pago.',
 'You can cancel your subscription at any time through your iPhone Settings > Apple ID > Subscriptions > Naplet > Cancel Subscription. You will continue to have access to Premium features until the end of the paid period.',
 'Puedes cancelar tu suscripción en cualquier momento a través de Configuración de tu iPhone > Apple ID > Suscripciones > Naplet > Cancelar Suscripción. Continuarás teniendo acceso a las funciones Premium hasta el final del período pagado.',
 2),

('subscription',
 'Posso usar em mais de um dispositivo?',
 'Can I use it on more than one device?',
 '¿Puedo usarlo en más de un dispositivo?',
 'Sim! Sua conta funciona em todos os seus dispositivos Apple. Basta fazer login com a mesma conta. Os dados são sincronizados automaticamente entre dispositivos.',
 'Yes! Your account works on all your Apple devices. Just log in with the same account. Data is automatically synced between devices.',
 '¡Sí! Tu cuenta funciona en todos tus dispositivos Apple. Solo inicia sesión con la misma cuenta. Los datos se sincronizan automáticamente entre dispositivos.',
 3),

('subscription',
 'Qual a diferença entre o plano mensal e anual?',
 'What''s the difference between monthly and annual plans?',
 '¿Cuál es la diferencia entre el plan mensual y anual?',
 'Ambos os planos oferecem exatamente os mesmos recursos. A diferença é apenas no preço: o plano anual oferece um desconto significativo (equivalente a 2 meses grátis). Você pode começar com o mensal e mudar para anual depois.',
 'Both plans offer exactly the same features. The difference is only in price: the annual plan offers a significant discount (equivalent to 2 free months). You can start with monthly and switch to annual later.',
 'Ambos planes ofrecen exactamente las mismas funciones. La diferencia es solo en el precio: el plan anual ofrece un descuento significativo (equivalente a 2 meses gratis). Puedes comenzar con el mensual y cambiar al anual después.',
 4),

-- TECHNICAL
('technical',
 'Os dados do meu bebê estão seguros?',
 'Is my baby''s data secure?',
 '¿Los datos de mi bebé están seguros?',
 'Sim! Levamos a segurança muito a sério. Todos os dados são criptografados e armazenados em servidores seguros. Nunca vendemos ou compartilhamos seus dados com terceiros. Você pode excluir seus dados a qualquer momento nas configurações.',
 'Yes! We take security very seriously. All data is encrypted and stored on secure servers. We never sell or share your data with third parties. You can delete your data at any time in settings.',
 '¡Sí! Nos tomamos la seguridad muy en serio. Todos los datos están encriptados y almacenados en servidores seguros. Nunca vendemos ni compartimos tus datos con terceros. Puedes eliminar tus datos en cualquier momento en configuración.',
 1),

('technical',
 'O app funciona offline?',
 'Does the app work offline?',
 '¿La app funciona sin internet?',
 'Você pode registrar sonos e atividades offline. Quando seu dispositivo se conectar à internet, os dados serão sincronizados automaticamente. O Chat IA requer conexão com a internet.',
 'You can log sleeps and activities offline. When your device connects to the internet, the data will be automatically synced. The AI Chat requires an internet connection.',
 'Puedes registrar sueños y actividades sin conexión. Cuando tu dispositivo se conecte a internet, los datos se sincronizarán automáticamente. El Chat IA requiere conexión a internet.',
 2),

('technical',
 'Como exporto os dados para o pediatra?',
 'How do I export data for the pediatrician?',
 '¿Cómo exporto los datos para el pediatra?',
 'Com o plano Premium, você pode gerar relatórios em PDF profissionais. Vá em Configurações > Relatórios e selecione o período desejado. O relatório inclui gráficos e estatísticas que ajudam na consulta médica.',
 'With the Premium plan, you can generate professional PDF reports. Go to Settings > Reports and select the desired period. The report includes charts and statistics that help during medical appointments.',
 'Con el plan Premium, puedes generar informes PDF profesionales. Ve a Configuración > Informes y selecciona el período deseado. El informe incluye gráficos y estadísticas que ayudan en la consulta médica.',
 3),

('technical',
 'O Naplet funciona no Apple Watch?',
 'Does Naplet work on Apple Watch?',
 '¿Naplet funciona en Apple Watch?',
 'Sim! O Naplet tem um app companion para Apple Watch que permite iniciar e parar o registro de sono diretamente do pulso. Perfeito para quando você está com o bebê no colo. O Apple Watch sincroniza automaticamente com o iPhone.',
 'Yes! Naplet has a companion app for Apple Watch that allows you to start and stop sleep tracking directly from your wrist. Perfect for when you''re holding the baby. The Apple Watch syncs automatically with iPhone.',
 '¡Sí! Naplet tiene una app complementaria para Apple Watch que permite iniciar y detener el registro de sueño directamente desde tu muñeca. Perfecto para cuando tienes al bebé en brazos. El Apple Watch sincroniza automáticamente con el iPhone.',
 4),

-- ACCOUNT
('account',
 'Como excluo minha conta?',
 'How do I delete my account?',
 '¿Cómo elimino mi cuenta?',
 'Você pode excluir sua conta em Configurações > Excluir Conta. Todos os seus dados serão permanentemente removidos de nossos servidores. Esta ação não pode ser desfeita. Se você tiver uma assinatura ativa, cancele-a primeiro nas configurações do iPhone.',
 'You can delete your account in Settings > Delete Account. All your data will be permanently removed from our servers. This action cannot be undone. If you have an active subscription, cancel it first in your iPhone settings.',
 'Puedes eliminar tu cuenta en Configuración > Eliminar Cuenta. Todos tus datos serán eliminados permanentemente de nuestros servidores. Esta acción no se puede deshacer. Si tienes una suscripción activa, cancélala primero en la configuración de tu iPhone.',
 1),

('account',
 'Esqueci minha senha, o que faço?',
 'I forgot my password, what do I do?',
 '¿Olvidé mi contraseña, qué hago?',
 'Na tela de login, toque em "Esqueci minha senha" e digite seu email. Você receberá um link para criar uma nova senha. Se você usa "Entrar com Apple", não precisa de senha - basta usar seu Face ID ou Touch ID.',
 'On the login screen, tap "Forgot password" and enter your email. You will receive a link to create a new password. If you use "Sign in with Apple", you don''t need a password - just use your Face ID or Touch ID.',
 'En la pantalla de inicio de sesión, toca "Olvidé mi contraseña" e ingresa tu email. Recibirás un enlace para crear una nueva contraseña. Si usas "Iniciar sesión con Apple", no necesitas contraseña - solo usa tu Face ID o Touch ID.',
 2),

('account',
 'Como altero meu email?',
 'How do I change my email?',
 '¿Cómo cambio mi email?',
 'No momento, não é possível alterar o email diretamente pelo app. Entre em contato conosco através do formulário de suporte e nossa equipe irá ajudá-lo com a alteração.',
 'Currently, it''s not possible to change your email directly through the app. Contact us through the support form and our team will help you with the change.',
 'Actualmente, no es posible cambiar tu email directamente a través de la app. Contáctanos a través del formulario de soporte y nuestro equipo te ayudará con el cambio.',
 3)

ON CONFLICT (id) DO NOTHING;

-- ============================================
-- 4. TRIGGER FOR UPDATED_AT
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for faq_items
DROP TRIGGER IF EXISTS update_faq_items_updated_at ON public.faq_items;
CREATE TRIGGER update_faq_items_updated_at
    BEFORE UPDATE ON public.faq_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for support_tickets
DROP TRIGGER IF EXISTS update_support_tickets_updated_at ON public.support_tickets;
CREATE TRIGGER update_support_tickets_updated_at
    BEFORE UPDATE ON public.support_tickets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- DONE!
-- ============================================
-- Execute this SQL in your Supabase Dashboard:
-- 1. Go to https://app.supabase.com
-- 2. Select your project
-- 3. Go to SQL Editor
-- 4. Paste this entire file and click "Run"
-- ============================================
