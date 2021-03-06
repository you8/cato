<%@ Page Language="C#" AutoEventWireup="true" MasterPageFile="~/pages/site.master"
    CodeBehind="systemStatusView.aspx.cs" Inherits="Web.pages.systemStatusView" %>

<asp:Content ID="cDetail" ContentPlaceHolderID="phDetail" runat="server">
    <script type="text/javascript" src="../script/systemStatusView.js"></script>
    <div id="left_panel">
        <div class="left_tooltip">
            <img src="../images/system-status-192x192.png" alt="" />
            <div id="left_tooltip_box_outer">
                <div id="left_tooltip_box_inner">
                    <p>
                        <img src="../images/tooltip.png" alt="" />The system status display shows up to
                        the minute information on system components, services and users.</p>
                    <p>
                        Rows which highlight on mouse-over will display more detailed data when clicked.
                    </p>
                    <p>
                        To refresh the data select the menu choice again.
                    </p>
                </div>
            </div>
        </div>
    </div>
    <div id="content" style="padding-top: 20px;">
        <div class="ui-widget-content ui-corner-all">
            <div class="ui-widget-header">
                <span>System Components</span>
			</div>
			<div style="padding: 10px;">	
	            <table class="jtable" cellspacing="1" cellpadding="1" width="95%">
	                <thead>
	                    <tr>
	                        <th align="left">
	                            Component
	                        </th>
	                        <th align="left">
	                            Instance
	                        </th>
	                        <th align="left">
	                            Load
	                        </th>
	                        <th align="left">
	                            Heartbeat
	                        </th>
	                        <th align="left">
	                            Enabled?
	                        </th>
	                        <th align="left">
	                            Minutes Since Last Report
	                        </th>
	                    </tr>
	                </thead>
	                <tbody>
	                    <asp:Repeater ID="rpSystemComponents" runat="server" OnItemDataBound="rpSystemComponents_ItemDataBound">
	                        <ItemTemplate>
	                            <tr>
	                                <td>
	                                    <%# (((System.Data.DataRowView)Container.DataItem)["Component"]) %>
	                                </td>
	                                <td>
	                                    <%# (((System.Data.DataRowView)Container.DataItem)["Instance"]) %>
	                                </td>
	                                <td>
	                                    <%# (((System.Data.DataRowView)Container.DataItem)["LoadValue"]) %>
	                                </td>
	                                <td>
	                                    <%# (((System.Data.DataRowView)Container.DataItem)["Heartbeat"]) %>
	                                </td>
	                                <td>
	                                    <%# (((System.Data.DataRowView)Container.DataItem)["Enabled"]) %>
	                                </td>
	                                <td>
	                                    <%# (((System.Data.DataRowView)Container.DataItem)["mslr"]) %>
	                                </td>
	                            </tr>
	                        </ItemTemplate>
	                    </asp:Repeater>
	                </tbody>
	            </table>
			</div>
        </div>
        <br />
        <div class="ui-widget-content ui-corner-all">
            <div class="ui-widget-header">
                <span>Current Users</span> <span class="security_log_link" id="show_log_link" class="pointer">
                    <img alt="" src="../images/icons/view_text_16.png" />
                    View Login History</span>
			</div>
			<div style="padding: 10px;">	
				<table class="jtable" cellspacing="1" cellpadding="1" width="95%">
		            <thead>
		                <tr>
		                    <th align="left">
		                        User
		                    </th>
		                    <th align="left">
		                        Login Time
		                    </th>
		                    <th align="left">
		                        Last Update
		                    </th>
		                    <th align="left">
		                        Address
		                    </th>
		                    <th align="left">
		                        Status
		                    </th>
		                </tr>
		            </thead>
		            <tbody>
		                <asp:Repeater ID="rptUsers" runat="server">
		                    <ItemTemplate>
		                        <tr>
		                            <td tag="selectuser">
		                                <%# (((System.Data.DataRowView)Container.DataItem)["full_name"]) %>
		                            </td>
		                            <td tag="selectuser">
		                                <%# (((System.Data.DataRowView)Container.DataItem)["login_dt"]) %>
		                            </td>
		                            <td tag="selectuser">
		                                <%# (((System.Data.DataRowView)Container.DataItem)["last_update"]) %>
		                            </td>
		                            <td tag="selectuser">
		                                <%# (((System.Data.DataRowView)Container.DataItem)["address"]) %>
		                            </td>
		                            <td tag="selectuser">
		                                <%# (((System.Data.DataRowView)Container.DataItem)["kick"]) %>
		                            </td>
		                        </tr>
		                    </ItemTemplate>
		                </asp:Repeater>
		            </tbody>
		        </table>
			</div>
        </div>
    </div>
</asp:Content>
