defmodule SlaxWeb.LiveViews.Terms do
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
      <H2>Revelry Labs, LLC Terms of Service</H2>
      <H3>1. Terms</H3>
      <P>By accessing the website at <A href="https://slax.co">https://slax.co</A>, you are agreeing to be bound by these terms of service, all applicable laws and regulations, and agree that you are responsible for compliance with any applicable local laws. If you do not agree with any of these terms, you are prohibited from using or accessing this site. The materials contained in this website are protected by applicable copyright and trademark law.</P>
      <H3>2. Use License</H3>
      <OL>
        <LI>Permission is granted to temporarily download one copy of the materials (information or software) on Revelry Labs, LLC's website for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title, and under this license you may not:
          <OL>
            <LI>modify or copy the materials;</LI>
            <LI>use the materials for any commercial purpose, or for any public display (commercial or non-commercial);</LI>
            <LI>attempt to decompile or reverse engineer any software contained on Revelry Labs, LLC's website;</LI>
            <LI>remove any copyright or other proprietary notations from the materials; or</LI>
            <LI>transfer the materials to another person or "mirror" the materials on any other server.</LI>
          </OL>
        </LI>
        <LI>This license shall automatically terminate if you violate any of these restrictions and may be terminated by Revelry Labs, LLC at any time. Upon terminating your viewing of these materials or upon the termination of this license, you must destroy any downloaded materials in your possession whether in electronic or printed format.</LI>
      </OL>
      <H3>3. Disclaimer</H3>
      <OL>
        <LI>The materials on Revelry Labs, LLC's website are provided on an 'as is' basis. Revelry Labs, LLC makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.</LI>
        <LI>Further, Revelry Labs, LLC does not warrant or make any representations concerning the accuracy, likely results, or reliability of the use of the materials on its website or otherwise relating to such materials or on any sites linked to this site.</LI>
      </OL>
      <H3>4. Limitations</H3>
      <P>In no event shall Revelry Labs, LLC or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the materials on Revelry Labs, LLC's website, even if Revelry Labs, LLC or a Revelry Labs, LLC authorized representative has been notified orally or in writing of the possibility of such damage. Because some jurisdictions do not allow limitations on implied warranties, or limitations of liability for consequential or incidental damages, these limitations may not apply to you.</P>
      <H3>5. Accuracy of materials</H3>
      <P>The materials appearing on Revelry Labs, LLC's website could include technical, typographical, or photographic errors. Revelry Labs, LLC does not warrant that any of the materials on its website are accurate, complete or current. Revelry Labs, LLC may make changes to the materials contained on its website at any time without notice. However Revelry Labs, LLC does not make any commitment to update the materials.</P>
      <H3>6. Links</H3>
      <P>Revelry Labs, LLC has not reviewed all of the sites linked to its website and is not responsible for the contents of any such linked site. The inclusion of any link does not imply endorsement by Revelry Labs, LLC of the site. Use of any such linked website is at the user's own risk.</P>
      <H3>7. Modifications</H3>
      <P>Revelry Labs, LLC may revise these terms of service for its website at any time without notice. By using this website you are agreeing to be bound by the then current version of these terms of service.</P>
      <H3>8. Governing Law</H3>
      <P>These terms and conditions are governed by and construed in accordance with the laws of Louisiana and you irrevocably submit to the exclusive jurisdiction of the courts in that State or location.</P>
    </Page>
    <PageFooter />
    """
  end
end
