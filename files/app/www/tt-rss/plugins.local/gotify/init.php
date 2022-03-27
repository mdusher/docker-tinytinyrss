<?php

class gotify extends Plugin {

        private $host;

        function about() {
                return array(1.0, "Gotify Webhook Filter", "danirod");
        }

        function flags() {
                return array("needs_curl" => true);
        }

        function api_version() {
                return 2;
        }

        function init($host) {
                $this->host = $host;

                $host->add_hook($host::HOOK_PREFS_TAB, $this);
                $host->add_hook($host::HOOK_ARTICLE_FILTER_ACTION, $this);

                $host->add_filter_action($this, "gotify_trigger", "Send article to the Gotify");
        }

        function save() {
                $gotify_webhook_url = $_POST["gotify_webhook_url"];
                $gotify_key = $_POST["gotify_key"];
                $this->host->set($this, "gotify_webhook_url", $gotify_webhook_url);
                $this->host->set($this, "gotify_key", $gotify_key);
        }

        function hook_prefs_tab($args) {
                if ($args != "prefPrefs") {
                        return;
                }

                $gotify_webhook_url = $this->host->get($this, "gotify_webhook_url");
                $gotify_key = $this->host->get($this, "gotify_key");

                print '
                        <div dojoType="dijit.layout.AccordionPane" title="Gotify Webhooks">
                                <p>Use these settings to configure the URL to send articles to whenever the filter gets executed.</p>
                                <form dojoType="dijit.form.Form">
                                        <script type="dojo/method" event="onSubmit" args="evt">
                                                evt.preventDefault();
                                                if (this.validate()) {
                                                        xhr.post("backend.php", this.getValues(), (reply) => {
                                                                Notify.info(reply);
                                                        });
                                                }
                                        </script>
                                        <input dojoType="dijit.form.TextBox" style="display: none" name="op" value="pluginhandler" />
                                        <input dojoType="dijit.form.TextBox" style="display: none" name="plugin" value="gotify" />
                                        <input dojoType="dijit.form.TextBox" style="display: none" name="method" value="save" />
                                        <table class="prefPrefsList">
                                                <tr>
                                                        <td width="40%">Webhook URL</td>
                                                        <td class="prefValue">
                                                                <input dojoType="dijit.form.ValidationTextBox" required="1" name="gotify_webhook_url"
                                                                           value="' . $gotify_webhook_url . '" placeholder="https://www.example.com/gotify/" />
                                                                <input dojoType="dijit.form.ValidationTextBox" required="1" name="gotify_key"
                                                                           value="' . $gotify_key . '" placeholder="X-Gotify-Key"/>
                                                        </td>
                                                </tr>
                                        </table>
                                        <p><button dojoType="dijit.form.Button" type="submit">Save changes</button></p>
                                </form>
                        </div>
                ';
        }

        function hook_article_filter_action($article, $action) {
                $gotify_webhook_url = $this->host->get($this, "gotify_webhook_url");
                $gotify_key = $this->host->get($this, "gotify_key");
                if ($gotify_webhook_url) {
                        $this->send_article($gotify_webhook_url, $gotify_key, $article['title'], $article['link']);
                }
                return $article; // leave untouched!
        }

        function send_article($webhook, $key, $title, $url) {
                /* Safety checks. */
                if (!$webhook || !$url || !$key) {
                        return;
                }

                /* Build payload. */
                if ($title) {
                        $payload = ["title" => "$title", "message" => "$url", "priority" => 1];
                } else {
                        /* Should not happen, but! */
                        $payload = ["title" => "$url", "message" => "$url", "priority" => 1];
                }

                /* Submit payload. */
                $curl = curl_init($webhook);
                curl_setopt($curl, CURLOPT_POST, true);
                curl_setopt($curl, CURLOPT_POSTFIELDS, json_encode($payload));
                curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
                curl_setopt($curl, CURLOPT_HTTPHEADER, ["Content-Type: application/json", "X-Gotify-Key: $key"]);
                $result = curl_exec($curl);
                curl_close($curl);
        }
}

