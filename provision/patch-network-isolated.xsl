<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <!-- Copy all elements and attributes as is -->
  <xsl:template match="node() | @*">
    <xsl:copy>
      <xsl:apply-templates select="node() | @*"/>
    </xsl:copy>
  </xsl:template>

  <!-- Match the network element and add the port element inside it -->
  <xsl:template match="network">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
      <port isolated="yes"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>
