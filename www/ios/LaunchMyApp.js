(function () {
    "use strict";

    /*
     * LaunchMyApp iOS JavaScript Bridge
     *
     * Provides methods to retrieve the launch URL for cold start scenarios
     * where handleOpenURL may not be called reliably (e.g., remote content apps).
     *
     * Copyright (c) 2024 Mobilozophy, LLC
     */

    var launchmyapp = {
        /**
         * Get the last URL that launched the app.
         * Does NOT clear the stored URL - use getLastUrlAndClear for that.
         *
         * @param {function} success - Called with URL string or null
         * @param {function} failure - Called on error
         */
        getLastUrl: function(success, failure) {
            cordova.exec(
                success,
                failure,
                "LaunchMyApp",
                "getLastUrl",
                []
            );
        },

        /**
         * Get the last URL and clear it from storage.
         * This is the typical use case - read once and consume.
         *
         * @param {function} success - Called with URL string or null
         * @param {function} failure - Called on error
         */
        getLastUrlAndClear: function(success, failure) {
            cordova.exec(
                success,
                failure,
                "LaunchMyApp",
                "getLastUrlAndClear",
                []
            );
        },

        /**
         * Clear the stored URL without reading it.
         *
         * @param {function} success - Called on success
         * @param {function} failure - Called on error
         */
        clearLastUrl: function(success, failure) {
            cordova.exec(
                success,
                failure,
                "LaunchMyApp",
                "clearLastUrl",
                []
            );
        }
    };

    module.exports = launchmyapp;

}());
