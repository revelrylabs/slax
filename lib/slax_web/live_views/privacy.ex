defmodule SlaxWeb.LiveViews.Privacy do
  @moduledoc false
  use SlaxWeb, :live_view

  @impl true
  def mount(_, session, socket) do
    socket = assign_user_props(socket, session)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~F"""
    <Page signed_in={@signed_in} avatar={@avatar}>
      <H2>Privacy Policy</H2>
      <P>Your privacy is important to us. It is Revelry Labs, LLC's policy to respect your privacy regarding any information we may collect from you across our website, <a href="https://lintron.io">https://lintron.io</a>, and other sites we own and operate.</P>
      <H3>1. Information we collect</H3>
      <H3>Log data</H3>
      <P>When you visit our website, our servers may automatically log the standard data provided by your web browser. It may include your computer’s Internet Protocol (IP) address, your browser type and version, the pages you visit, the time and date of your visit, the time spent on each page, and other details.</P>
      <H3>Device data</H3>
      <P>We may also collect data about the device you’re using to access our website. This data may include the device type, operating system, unique device identifiers, device settings, and geo-location data. What we collect can depend on the individual settings of your device and software. We recommend checking the policies of your device manufacturer or software provider to learn what information they make available to us.</P>
      <H3>Personal information</H3>
      <OL>
        <LI>We may ask for personal information, such as your:
          <OL>
            <LI>Name</LI>
            <LI>Email</LI>
            <LI>Social media profiles</LI>
            <LI>Date of birth</LI>
            <LI>Phone/mobile number</LI>
            <LI>
              Home/Mailing address</LI>
            <LI>Work address</LI>
            <LI>Payment information</LI>
          </OL>
        </LI>
      </OL>
      <H3>2. Legal bases for processing</H3>
      <OL>
        <P>We will process your personal information lawfully, fairly and in a transparent manner. We collect and process information about you only where we have legal bases for doing so.</P>
        <P>These legal bases depend on the services you use and how you use them, meaning we collect and use your information only where:</P>
        <OL>
          <LI>it’s necessary for the performance of a contract to which you are a party or to take steps at your request before entering into such a contract (for example, when we provide a service you request from us)</LI>
          <LI>it satisfies a legitimate interest (which is not overridden by your data protection interests), such as for research and development, to market and promote our services, and to protect our legal rights and interests</LI>
          <LI>you give us consent to do so for a specific purpose (for example, you might consent to us sending you our newsletter); or
          </LI>
          <LI>we need to process your data to comply with a legal obligation.</LI>
        </OL>
        <P>Where you consent to our use of information about you for a specific purpose, you have the right to change your mind at any time (but this will not affect any processing that has already taken place).</P>
        <P>We don’t keep personal information for longer than is necessary. While we retain this information, we will protect it within commercially acceptable means to prevent loss and theft, as well as unauthorized access, disclosure, copying, use or modification. That said, we advise that no method of electronic transmission or storage is 100% secure and cannot guarantee absolute data security. If necessary, we may retain your personal information for our compliance with a legal obligation or in order to protect your vital interests or the vital interests of another natural person.</P>
      </OL>
      <H3>3. Collection and use of information</H3>
      <OL>
        <LI>to enable you to customize or personalize your experience of our website;</LI>
        <LI>to enable you to access and use our website, associated applications and associated social media platforms;</LI>
        <LI>to contact and communicate with you;</LI>
        <LI>for internal record keeping and administrative purposes;</LI>
        <LI>for analytics, market research and business development, including to operate and improve our website, associated applications and associated social media platforms;</LI>
        <LI>to run competitions and/or offer additional benefits to you;</LI>
        <LI>for advertising and marketing, including to send you promotional information about our products and services and information about third parties that we consider may be of interest to you;</LI>
        <LI>to comply with our legal obligations and resolve any disputes that we may have; and</LI>
        <LI>to consider your employment application.</LI>
      </OL>
      <H3>4. Limitations</H3>
      <OL>
        We may disclose personal information to:
        <LI>third party service providers for the purpose of enabling them to provide their services, including (without limitation) IT service providers, data storage, hosting and server providers, ad networks, analytics, error loggers, debt collectors, maintenance or problem-solving providers, marketing or advertising providers, professional advisors and payment systems operators</LI>
        <LI>our employees, contractors and/or related entities</LI>
        <LI>sponsors or promoters of any competition we run</LI>
        <LI>credit reporting agencies, courts, tribunals and regulatory authorities, in the event you fail to pay for goods or services we have provided to you</LI>
        <LI>courts, tribunals, regulatory authorities and law enforcement officers, as required by law, in connection with any actual or prospective legal proceedings, or in order to establish, exercise or defend our legal rights</LI>
        <LI>third parties, including agents or sub-contractors, who assist us in providing information, products, services or direct marketing to you</LI> and
        <LI>third parties to collect and process data</LI>
      </OL>
      <H3>5. International transfers of personal information</H3>
      <P>The personal information we collect is stored and processed in United States, or where we or our partners, affiliates and third-party providers maintain facilities. By providing us with your personal information, you consent to the disclosure to these overseas third parties.</P>
      <P>We will ensure that any transfer of personal information from countries in the European Economic Area (EEA) to countries outside the EEA will be protected by appropriate safeguards, for example by using standard data protection clauses approved by the European Commission, or the use of binding corporate rules or other legally accepted means.</P>
      <P>Where we transfer personal information from a non-EEA country to another country, you acknowledge that third parties in other jurisdictions may not be subject to similar data protection laws to the ones in our jurisdiction. There are risks if any such third party engages in any act or practice that would contravene the data privacy laws in our jurisdiction and this might mean that you will not be able to seek redress under our jurisdiction’s privacy laws.</P>
      <H3>6. Your rights and controlling your personal information</H3>
      <P>Choice and consent: By providing personal information to us, you consent to us collecting, holding, using and disclosing your personal information in accordance with this privacy policy. If you are under 16 years of age, you must have, and warrant to the extent permitted by law to us, that you have your parent or legal guardian’s permission to access and use the website and they (your parents or guardian) have consented to you providing us with your personal information. You do not have to provide personal information to us, however, if you do not, it may affect your use of this website or the products and/or services offered on or through it.</P>
      <P>Information from third parties: If we receive personal information about you from a third party, we will protect it as set out in this privacy policy. If you are a third party providing personal information about somebody else, you represent and warrant that you have such person’s consent to provide the personal information to us.</P>
      <P>Restrict: You may choose to restrict the collection or use of your personal information. If you have previously agreed to us using your personal information for direct marketing purposes, you may change your mind at any time by contacting us using the details below. If you ask us to restrict or limit how we process your personal information, we will let you know how the restriction affects your use of our website or products and services.</P>
      <P>Access and data portability: You may request details of the personal information that we hold about you. You may request a copy of the personal information we hold about you. Where possible, we will provide this information in CSV format or other easily readable machine format. You may request that we erase the personal information we hold about you at any time. You may also request that we transfer this personal information to another third party.</P>
      <P>Correction: If you believe that any information we hold about you is inaccurate, out of date, incomplete, irrelevant or misleading, please contact us using the details below. We will take reasonable steps to correct any information found to be inaccurate, incomplete, misleading or out of date.</P>
      <P>Notification of data breaches: We will comply laws applicable to us in respect of any data breach.</P>
      <P>Complaints: If you believe that we have breached a relevant data protection law and wish to make a complaint, please contact us using the details below and provide us with full details of the alleged breach. We will promptly investigate your complaint and respond to you, in writing, setting out the outcome of our investigation and the steps we will take to deal with your complaint. You also have the right to contact a regulatory body or data protection authority in relation to your complaint.</P>
      <P>Unsubscribe: To unsubscribe from our e-mail database or opt-out of communications (including marketing communications), please contact us using the details below or opt-out using the opt-out facilities provided in the communication.</P>
      <H3>7. Cookies</H3>
      <P>We use "cookies" to collect information about you and your activity across our site. A cookie is a small piece of data that our website stores on your computer, and accesses each time you visit, so we can understand how you use our site. This helps us serve you content based on preferences you have specified. Please refer to our Cookie Policy for more information.</P>
      <H3>8. Business transfers</H3>
      <P>If we or our assets are acquired, or in the unlikely event that we go out of business or enter bankruptcy, we would include data among the assets transferred to any parties who acquire us. You acknowledge that such transfers may occur, and that any parties who acquire us may continue to use your personal information according to this policy.</P>
      <H3>9. Limits of our policy</H3>
      <P>Our website may link to external sites that are not operated by us. Please be aware that we have no control over the content and policies of those sites, and cannot accept responsibility or liability for their respective privacy practices.</P>
      <H3>10. Changes to this policy</H3>
      <P>At our discretion, we may change our privacy policy to reflect current acceptable practices. We will take reasonable steps to let users know about changes via our website. Your continued use of this site after any changes to this policy will be regarded as acceptance of our practices around privacy and personal information.</P>
      <P>If we make a significant change to this privacy policy, for example changing a lawful basis on which we process your personal information, we will ask you to re-consent to the amended privacy policy.</P>
      <P>Revelry Labs, LLC Data Controller
      </P>
      <P>Slax Support</P>
      <P>support+slax@revelry.co</P>
      <P>This policy is effective as of Aug 12, 2021.</P>
    </Page>
    """
  end
end
