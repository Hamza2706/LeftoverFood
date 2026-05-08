using System;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;

namespace LeftoverFoodSystem
{
    public class DBHelper
    {
        // Connection string is stored in Web.config
        private static string connStr = ConfigurationManager.ConnectionStrings["FoodDB"].ConnectionString;

        // Returns an open SqlConnection
        public static SqlConnection GetConnection()
        {
            SqlConnection conn = new SqlConnection(connStr);
            conn.Open();
            return conn;
        }

        // Execute INSERT / UPDATE / DELETE — returns rows affected
        public static int ExecuteNonQuery(string query, SqlParameter[] parameters = null)
        {
            using (SqlConnection conn = GetConnection())
            using (SqlCommand cmd = new SqlCommand(query, conn))
            {
                if (parameters != null)
                    cmd.Parameters.AddRange(parameters);
                return cmd.ExecuteNonQuery();
            }
        }

        // Execute SELECT — returns a DataTable
        public static DataTable ExecuteQuery(string query, SqlParameter[] parameters = null)
        {
            using (SqlConnection conn = GetConnection())
            using (SqlCommand cmd = new SqlCommand(query, conn))
            {
                if (parameters != null)
                    cmd.Parameters.AddRange(parameters);

                SqlDataAdapter da = new SqlDataAdapter(cmd);
                DataTable dt = new DataTable();
                da.Fill(dt);
                return dt;
            }
        }

        // Execute SELECT — returns a single value (e.g. COUNT, ID)
        public static object ExecuteScalar(string query, SqlParameter[] parameters = null)
        {
            using (SqlConnection conn = GetConnection())
            using (SqlCommand cmd = new SqlCommand(query, conn))
            {
                if (parameters != null)
                    cmd.Parameters.AddRange(parameters);
                return cmd.ExecuteScalar();
            }
        }
    }
}
